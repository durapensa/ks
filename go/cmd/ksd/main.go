package main

import (
	"encoding/json"
	"fmt"
	"log"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"time"

	"github.com/fsnotify/fsnotify"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/durapensa/ks/pkg/config"
)

var (
	// Build info set by linker
	buildTime = "unknown"
	version   = "dev"
)

// Screen types
type screenType int

const (
	dashboardScreen screenType = iota
	searchScreen
	analyticsScreen
	processScreen
	captureScreen
)

// Styles
var (
	titleStyle = lipgloss.NewStyle().
		Bold(true).
		Foreground(lipgloss.Color("205")).
		Align(lipgloss.Center).
		MarginBottom(1)

	headerStyle = lipgloss.NewStyle().
		Bold(true).
		Foreground(lipgloss.Color("212")).
		MarginBottom(1)

	statusStyle = lipgloss.NewStyle().
		Foreground(lipgloss.Color("248"))

	pendingStyle = lipgloss.NewStyle().
		Foreground(lipgloss.Color("214"))

	readyStyle = lipgloss.NewStyle().
		Foreground(lipgloss.Color("46"))

	helpStyle = lipgloss.NewStyle().
		Foreground(lipgloss.Color("241")).
		MarginTop(1)

	separatorStyle = lipgloss.NewStyle().
		Foreground(lipgloss.Color("237"))

	selectedStyle = lipgloss.NewStyle().
		Background(lipgloss.Color("237")).
		Foreground(lipgloss.Color("255"))

	normalStyle = lipgloss.NewStyle().
		Foreground(lipgloss.Color("252"))
)

// Event structure for parsing JSONL
type Event struct {
	Timestamp   string                 `json:"ts"`                  // Actual field name is "ts"
	Type        string                 `json:"type"`
	Content     string                 `json:"content,omitempty"`   // Most events use "content"
	Topic       string                 `json:"topic,omitempty"`     // Some events have topic
	Thought     string                 `json:"thought,omitempty"`   // Legacy support
	Observation string                 `json:"observation,omitempty"` // Legacy support
	Question    string                 `json:"question,omitempty"`  // Legacy support
	Context     string                 `json:"context,omitempty"`
	Tags        []string               `json:"tags,omitempty"`
	Metadata    map[string]interface{} `json:"metadata,omitempty"`
	RawJSON     string                 // Store the original JSON line for pretty printing
}

// Dashboard data
type dashboardData struct {
	totalEvents       int
	pendingCount      int
	activeProcesses   int
	eventsUntilTheme  int
	eventsUntilConn   int
	eventsUntilPatt   int
	lastUpdate        string
	latestEvent       *Event
}

// Model represents the TUI state
type model struct {
	config        *config.Config
	currentScreen screenType
	dashboard     dashboardData
	width         int
	height        int
	error         error
	searchResults []string
	searchTerm    string
	searchInput   string
	loading       bool
	inputMode     bool
}

// Messages
type dashboardMsg struct {
	data dashboardData
}

type errorMsg struct {
	err error
}

type searchResultsMsg struct {
	results []string
	term    string
}

type fileWatchMsg struct {
	event fsnotify.Event
}

type fileWatchErrorMsg struct {
	err error
}

// Initialize the model
func initialModel() model {
	cfg, err := config.LoadKSEnv()
	if err != nil {
		return model{error: err}
	}

	return model{
		config:        cfg,
		currentScreen: dashboardScreen,
		dashboard:     dashboardData{},
	}
}

func (m model) Init() tea.Cmd {
	return tea.Batch(
		loadDashboardDataWithConfig(m.config),
		watchFile(m.config.HotLog), // Start file watching
	)
}

// Command to watch a file for changes using fsnotify
// This follows Bubbletea's pattern: a command waits for ONE event and returns it as a message
func watchFile(path string) tea.Cmd {
	return func() tea.Msg {
		if path == "" {
			return fileWatchErrorMsg{err: fmt.Errorf("no file path provided")}
		}

		watcher, err := fsnotify.NewWatcher()
		if err != nil {
			return fileWatchErrorMsg{err: err}
		}
		defer watcher.Close()

		err = watcher.Add(path)
		if err != nil {
			return fileWatchErrorMsg{err: err}
		}

		// Wait for ONE event and return it as a message
		// Bubbletea's runtime automatically handles this in a goroutine
		select {
		case event, ok := <-watcher.Events:
			if !ok {
				return fileWatchErrorMsg{err: fmt.Errorf("watcher events channel closed")}
			}
			return fileWatchMsg{event: event}
		case err, ok := <-watcher.Errors:
			if !ok {
				return fileWatchErrorMsg{err: fmt.Errorf("watcher errors channel closed")}
			}
			return fileWatchErrorMsg{err: err}
		}
	}
}

// Parse the latest event from the hot log
func parseLatestEvent(cfg *config.Config) *Event {
	if cfg.HotLog == "" {
		return nil
	}

	file, err := os.Open(cfg.HotLog)
	if err != nil {
		return nil
	}
	defer file.Close()

	// Read file backwards to get the last line
	stat, err := file.Stat()
	if err != nil {
		return nil
	}

	if stat.Size() == 0 {
		return nil
	}

	// Read the last few bytes to find the last line
	buf := make([]byte, min(1024, int(stat.Size())))
	_, err = file.ReadAt(buf, max(0, stat.Size()-int64(len(buf))))
	if err != nil {
		return nil
	}

	// Find the last complete line
	lines := strings.Split(string(buf), "\n")
	var lastLine string
	for i := len(lines) - 1; i >= 0; i-- {
		if strings.TrimSpace(lines[i]) != "" {
			lastLine = strings.TrimSpace(lines[i])
			break
		}
	}

	if lastLine == "" {
		return nil
	}

	// Parse the JSON
	var event Event
	if err := json.Unmarshal([]byte(lastLine), &event); err != nil {
		return nil
	}

	// Store the raw JSON for pretty printing
	event.RawJSON = lastLine

	return &event
}

// Helper functions for min/max
func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}

func max(a, b int64) int64 {
	if a > b {
		return a
	}
	return b
}

// getBashPath returns the configured bash path (required for consistent bash 5.x behavior)
func getBashPath() string {
	return "bash"
}

// getCurrentDir returns the current working directory
func getCurrentDir() string {
	if dir, err := os.Getwd(); err == nil {
		return dir
	}
	return "unknown"
}

// Load dashboard data from system with config
func loadDashboardDataWithConfig(cfg *config.Config) tea.Cmd {
	return func() tea.Msg {
		// Get event count - use bash command for both modes (consistent with status mode)
		var totalEvents int
		cmd := exec.Command("bash", "-c", "source ~/.ks-env 2>/dev/null || source .ks-env; source $KS_ROOT/lib/core.sh; source $KS_ROOT/lib/events.sh; ks_count_new_events")
		if cfg.IsConversation {
			// Set working directory for conversation context
			cmd.Dir = cfg.ConversationDir
		}
		if output, err := cmd.Output(); err == nil {
			totalEvents, _ = strconv.Atoi(strings.TrimSpace(string(output)))
		}

		// Get pending analyses count
		var pendingCount int
		pendingCmd := exec.Command("bash", "-c", "source ~/.ks-env 2>/dev/null || source .ks-env; source $KS_ROOT/lib/core.sh; source $KS_ROOT/tools/lib/queue.sh; ks_queue_list_pending | jq 'length'")
		if output, err := pendingCmd.Output(); err == nil {
			pendingCount, _ = strconv.Atoi(strings.TrimSpace(string(output)))
		}

		// Get latest event
		latestEvent := parseLatestEvent(cfg)

		return dashboardMsg{
			data: dashboardData{
				totalEvents:     totalEvents,
				pendingCount:    pendingCount,
				activeProcesses: 0, // TODO: implement
				eventsUntilTheme: 10 - (totalEvents % 10),
				eventsUntilConn:  20 - (totalEvents % 20),
				eventsUntilPatt:  30 - (totalEvents % 30),
				lastUpdate:      time.Now().Format("15:04:05"),
				latestEvent:     latestEvent,
			},
		}
	}
}

// Handle external tool execution
func runExternalTool(tool string, args ...string) tea.Cmd {
	cmd := exec.Command(tool, args...)
	return tea.ExecProcess(cmd, func(err error) tea.Msg {
		if err != nil {
			return errorMsg{fmt.Errorf("running %s: %w", tool, err)}
		}
		return nil // Tool executed successfully
	})
}

// Handle external tool execution with config context
func runExternalToolWithConfig(cfg *config.Config, command string) tea.Cmd {
	// Build environment-aware command
	fullCommand := fmt.Sprintf("source ~/.ks-env 2>/dev/null || source .ks-env; %s", command)
	
	// If we're in a conversation directory, set working directory
	cmd := exec.Command("bash", "-c", fullCommand)
	if cfg.IsConversation {
		cmd.Dir = cfg.ConversationDir
	}
	
	return tea.ExecProcess(cmd, func(err error) tea.Msg {
		if err != nil {
			return errorMsg{fmt.Errorf("running %s: %w", command, err)}
		}
		return nil // Tool executed successfully
	})
}

// Search knowledge base with context awareness
func searchKnowledgeWithConfig(cfg *config.Config, term string) tea.Cmd {
	return func() tea.Msg {
		cmd := exec.Command("bash", "-c", fmt.Sprintf("source ~/.ks-env 2>/dev/null || source .ks-env; $KS_ROOT/tools/capture/query '%s'", term))
		
		// If we're in a conversation directory, set working directory
		if cfg.IsConversation {
			cmd.Dir = cfg.ConversationDir
		}
		
		output, err := cmd.Output()
		if err != nil {
			return errorMsg{fmt.Errorf("searching: %w", err)}
		}
		
		lines := strings.Split(strings.TrimSpace(string(output)), "\n")
		return searchResultsMsg{results: lines, term: term}
	}
}

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "ctrl+c", "q":
			return m, tea.Quit

		// Screen navigation
		case "1", "d":
			m.currentScreen = dashboardScreen
			return m, nil
		case "2", "s":
			m.currentScreen = searchScreen
			return m, nil
		case "3", "a":
			m.currentScreen = analyticsScreen
			return m, nil
		case "4", "p":
			m.currentScreen = processScreen
			return m, nil
		case "5", "c":
			m.currentScreen = captureScreen
			return m, nil

		// Dashboard actions
		case "r":
			if m.currentScreen == dashboardScreen && m.dashboard.pendingCount > 0 {
				return m, runExternalToolWithConfig(m.config, "$KS_ROOT/tools/introspect/review-findings")
			}
		case "t":
			if m.currentScreen == dashboardScreen {
				return m, runExternalToolWithConfig(m.config, "$KS_ROOT/tools/plumbing/check-event-triggers --verbose")
			}
		case "x":
			// Launch fx viewer for knowledge exploration
			hotLogPath := m.config.HotLog
			if hotLogPath == "" {
				hotLogPath = "$KS_HOT_LOG"
			}
			return m, runExternalToolWithConfig(m.config, fmt.Sprintf("fx %s", hotLogPath))
		case "k":
			// Quick kg query
			if m.currentScreen == dashboardScreen {
				return m, runExternalToolWithConfig(m.config, "$KS_ROOT/tools/kg/query --stats")
			}
		case "f":
			return m, loadDashboardDataWithConfig(m.config)
			
		// Search actions
		case "enter":
			if m.currentScreen == searchScreen {
				if m.inputMode {
					m.inputMode = false
					m.searchTerm = m.searchInput
					return m, searchKnowledgeWithConfig(m.config, m.searchInput)
				} else {
					m.inputMode = true
					m.searchInput = ""
				}
			}
		case "esc":
			if m.inputMode {
				m.inputMode = false
				m.searchInput = ""
			}
		case "backspace":
			if m.inputMode && len(m.searchInput) > 0 {
				m.searchInput = m.searchInput[:len(m.searchInput)-1]
			}
		default:
			// Handle text input for search
			if m.inputMode && m.currentScreen == searchScreen {
				if len(msg.String()) == 1 {
					m.searchInput += msg.String()
				}
			}
		}

	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height

	case dashboardMsg:
		m.dashboard = msg.data
		m.loading = false

	case searchResultsMsg:
		m.searchResults = msg.results
		m.searchTerm = msg.term

	case errorMsg:
		m.error = msg.err
		m.loading = false

	case fileWatchMsg:
		// File was modified, reload dashboard and continue watching
		if msg.event.Op&fsnotify.Write == fsnotify.Write {
			return m, tea.Batch(
				loadDashboardDataWithConfig(m.config),
				watchFile(m.config.HotLog), // Continue watching
			)
		}
		// For other operations, just continue watching
		return m, watchFile(m.config.HotLog)

	case fileWatchErrorMsg:
		// Log error and continue watching after a brief delay
		log.Printf("File watch error: %v", msg.err)
		return m, tea.Sequence(
			tea.Tick(time.Second*2, func(time.Time) tea.Msg { return nil }), // Wait 2 seconds
			watchFile(m.config.HotLog), // Restart watching
		)
	}

	return m, nil
}

func (m model) View() string {
	if m.error != nil {
		return fmt.Sprintf("Error: %v\n\nPress q to quit.", m.error)
	}

	// Title with context and path info
	var title string
	var pathInfo string
	if m.config.IsConversation {
		title = titleStyle.Width(80).Render(fmt.Sprintf("KNOWLEDGE SYSTEM - %s", strings.ToUpper(m.config.ContextName)))
		pathInfo = statusStyle.Render(fmt.Sprintf("Knowledge: %s | Build: %s", m.config.KnowledgeDir, buildTime))
	} else {
		title = titleStyle.Width(80).Render("KNOWLEDGE SYSTEM DASHBOARD")
		pathInfo = statusStyle.Render(fmt.Sprintf("Knowledge: %s | Hot Log: %s | Build: %s", m.config.KnowledgeDir, m.config.HotLog, buildTime))
	}
	
	// Debug info for conversation detection
	debugInfo := statusStyle.Render(fmt.Sprintf("IsConversation: %v | PWD: %s | Hot: %s", 
		m.config.IsConversation, getCurrentDir(), m.config.HotLog))
	
	// Navigation breadcrumb with context info
	var breadcrumb string
	switch m.currentScreen {
	case dashboardScreen:
		breadcrumb = "Dashboard"
	case searchScreen:
		breadcrumb = "Search"
	case analyticsScreen:
		breadcrumb = "Analytics"
	case processScreen:
		breadcrumb = "Processes"
	case captureScreen:
		breadcrumb = "Capture"
	}
	
	contextInfo := ""
	if m.config.IsConversation {
		contextInfo = fmt.Sprintf(" | Context: %s", m.config.ContextName)
	}
	
	nav := statusStyle.Render(fmt.Sprintf("Current: %s%s", breadcrumb, contextInfo))
	separator := separatorStyle.Render(strings.Repeat("═", 80))

	// Screen content
	var content string
	switch m.currentScreen {
	case dashboardScreen:
		content = m.renderDashboard()
	case searchScreen:
		content = m.renderSearch()
	case analyticsScreen:
		content = m.renderAnalytics()
	case processScreen:
		content = m.renderProcesses()
	case captureScreen:
		content = m.renderCapture()
	}

	// Help text
	help := m.renderHelp()

	return fmt.Sprintf("%s\n%s\n%s\n%s\n%s\n\n%s\n\n%s", title, pathInfo, debugInfo, nav, separator, content, help)
}

func (m model) renderDashboard() string {
	d := m.dashboard
	
	// Status line
	status := fmt.Sprintf("Events: %s | Reviews: %s | Active: %d | Updated: %s",
		readyStyle.Render(strconv.Itoa(d.totalEvents)),
		func() string {
			if d.pendingCount > 0 {
				return pendingStyle.Render(strconv.Itoa(d.pendingCount))
			}
			return "0"
		}(),
		d.activeProcesses,
		d.lastUpdate)

	// Analysis triggers
	triggers := "ANALYSIS TRIGGERS:\n"
	
	themeStatus := func() string {
		if d.eventsUntilTheme <= 0 {
			return readyStyle.Render("Ready")
		}
		return fmt.Sprintf("%d to go", d.eventsUntilTheme)
	}()
	
	connStatus := func() string {
		if d.eventsUntilConn <= 0 {
			return readyStyle.Render("Ready")
		}
		return fmt.Sprintf("%d to go", d.eventsUntilConn)
	}()
	
	pattStatus := func() string {
		if d.eventsUntilPatt <= 0 {
			return readyStyle.Render("Ready")
		}
		return fmt.Sprintf("%d to go", d.eventsUntilPatt)
	}()

	triggers += fmt.Sprintf("  Theme: %s | Connections: %s | Patterns: %s",
		themeStatus, connStatus, pattStatus)

	// Latest event section - enhanced display
	latestEventSection := ""
	if d.latestEvent != nil {
		latestEventSection = separatorStyle.Render(strings.Repeat("─", 80)) + "\n"
		latestEventSection += headerStyle.Render("LATEST EVENT") + "\n"
		
		// Format timestamp
		timestamp := d.latestEvent.Timestamp
		if len(timestamp) > 19 {
			timestamp = timestamp[:19] // Keep full date and time
		}
		
		// Header line with type and timestamp
		latestEventSection += fmt.Sprintf("Type: %s | Time: %s\n",
			readyStyle.Render(d.latestEvent.Type),
			normalStyle.Render(timestamp))
		
		// Get main content - prioritize new format, fallback to legacy
		var content string
		if d.latestEvent.Content != "" {
			content = d.latestEvent.Content
		} else if d.latestEvent.Thought != "" {
			content = d.latestEvent.Thought
		} else if d.latestEvent.Observation != "" {
			content = d.latestEvent.Observation
		} else if d.latestEvent.Question != "" {
			content = d.latestEvent.Question
		} else {
			content = "No content"
		}
		
		// Content section - allow up to 3 lines
		if content != "" {
			// Wrap content to fit within reasonable line lengths (70 chars per line)
			const maxLineLength = 70
			const maxLines = 3
			
			var lines []string
			remaining := content
			
			for len(lines) < maxLines && len(remaining) > 0 {
				if len(remaining) <= maxLineLength {
					lines = append(lines, remaining)
					break
				}
				
				// Find a good break point (space, comma, period) near the max length
				breakPoint := maxLineLength
				if breakPoint > len(remaining) {
					breakPoint = len(remaining)
				}
				
				// Look for word boundaries to avoid breaking mid-word
				for i := breakPoint - 1; i >= breakPoint - 20 && i >= 0; i-- {
					if i < len(remaining) && (remaining[i] == ' ' || remaining[i] == ',' || remaining[i] == '.') {
						breakPoint = i + 1
						break
					}
				}
				
				lines = append(lines, strings.TrimSpace(remaining[:breakPoint]))
				remaining = strings.TrimSpace(remaining[breakPoint:])
			}
			
			// Add ellipsis if content was truncated
			if len(remaining) > 0 {
				if len(lines) == maxLines {
					lastLine := lines[maxLines-1]
					if len(lastLine) > maxLineLength-3 {
						lines[maxLines-1] = lastLine[:maxLineLength-3] + "..."
					} else {
						lines[maxLines-1] = lastLine + "..."
					}
				}
			}
			
			latestEventSection += "Content:\n"
			for _, line := range lines {
				latestEventSection += "  " + normalStyle.Render(line) + "\n"
			}
		}
		
		// Topic if available
		if d.latestEvent.Topic != "" {
			latestEventSection += "Topic: " + readyStyle.Render(d.latestEvent.Topic) + "\n"
		}
		
		// Context if available
		if d.latestEvent.Context != "" {
			latestEventSection += "Context: " + statusStyle.Render(d.latestEvent.Context) + "\n"
		}
		
		// Tags if available
		if len(d.latestEvent.Tags) > 0 {
			tagStr := strings.Join(d.latestEvent.Tags, ", ")
			latestEventSection += "Tags: " + pendingStyle.Render(tagStr) + "\n"
		}
		
		// Metadata if available
		if len(d.latestEvent.Metadata) > 0 {
			latestEventSection += "Metadata:\n"
			for key, value := range d.latestEvent.Metadata {
				if valueStr, ok := value.(string); ok {
					if len(valueStr) > 50 {
						valueStr = valueStr[:47] + "..."
					}
					latestEventSection += fmt.Sprintf("  %s: %s\n", 
						statusStyle.Render(key), 
						normalStyle.Render(valueStr))
				} else {
					latestEventSection += fmt.Sprintf("  %s: %s\n", 
						statusStyle.Render(key), 
						normalStyle.Render(fmt.Sprintf("%v", value)))
				}
			}
		}
	}

	// Pending reviews
	pending := ""
	if d.pendingCount > 0 {
		pending = separatorStyle.Render(strings.Repeat("─", 80)) + "\n"
		pending += "PENDING REVIEWS:\n"
		pending += fmt.Sprintf("  %d analysis/analyses ready for review", d.pendingCount)
	}

	return fmt.Sprintf("%s\n%s\n%s\n%s\n%s", status, separatorStyle.Render(strings.Repeat("─", 80)), triggers, latestEventSection, pending)
}

func (m model) renderSearch() string {
	content := headerStyle.Render("SEARCH KNOWLEDGE BASE") + "\n\n"
	
	// Input section
	if m.inputMode {
		content += "Enter search term: " + selectedStyle.Render(m.searchInput+"_") + "\n"
		content += helpStyle.Render("Press Enter to search, Esc to cancel") + "\n\n"
	} else {
		content += "Press Enter to start search\n\n"
	}
	
	// Results section
	if len(m.searchResults) > 0 {
		content += separatorStyle.Render(strings.Repeat("─", 60)) + "\n"
		content += fmt.Sprintf("Results for '%s' (%d found):\n\n", m.searchTerm, len(m.searchResults))
		
		displayed := 0
		for _, result := range m.searchResults {
			if strings.TrimSpace(result) == "" {
				continue
			}
			if displayed >= 10 { // Limit display
				content += helpStyle.Render(fmt.Sprintf("... and %d more results", len(m.searchResults)-displayed)) + "\n"
				break
			}
			content += normalStyle.Render("• " + result) + "\n"
			displayed++
		}
	}
	
	return content
}

func (m model) renderAnalytics() string {
	d := m.dashboard
	content := headerStyle.Render("KNOWLEDGE SYSTEM ANALYTICS") + "\n\n"
	
	content += fmt.Sprintf("Total Events: %s\n", readyStyle.Render(strconv.Itoa(d.totalEvents)))
	content += fmt.Sprintf("Pending Reviews: %s\n", pendingStyle.Render(strconv.Itoa(d.pendingCount)))
	content += fmt.Sprintf("Active Processes: %d\n", d.activeProcesses)
	content += "\n"
	content += "Analysis Readiness:\n"
	content += fmt.Sprintf("  Theme Extraction: %s\n", func() string {
		if d.eventsUntilTheme <= 0 {
			return readyStyle.Render("Ready")
		}
		return fmt.Sprintf("%d events needed", d.eventsUntilTheme)
	}())
	content += fmt.Sprintf("  Connection Finding: %s\n", func() string {
		if d.eventsUntilConn <= 0 {
			return readyStyle.Render("Ready")
		}
		return fmt.Sprintf("%d events needed", d.eventsUntilConn)
	}())
	
	return content
}

func (m model) renderProcesses() string {
	content := headerStyle.Render("BACKGROUND PROCESSES") + "\n\n"
	
	// Active processes
	content += fmt.Sprintf("ACTIVE: %s\n", func() string {
		if m.dashboard.activeProcesses > 0 {
			return pendingStyle.Render(strconv.Itoa(m.dashboard.activeProcesses))
		}
		return "None"
	}())
	
	// Pending reviews
	if m.dashboard.pendingCount > 0 {
		content += fmt.Sprintf("\nPENDING (%d):\n", m.dashboard.pendingCount)
		content += readyStyle.Render("• Reviews available for processing") + "\n"
	} else {
		content += "\nPENDING: None\n"
	}
	
	// Analysis triggers status
	content += "\nTRIGGERS:\n"
	d := m.dashboard
	
	themeReady := d.eventsUntilTheme <= 0
	connReady := d.eventsUntilConn <= 0
	pattReady := d.eventsUntilPatt <= 0
	
	if themeReady {
		content += readyStyle.Render("• Theme extraction ready") + "\n"
	} else {
		content += fmt.Sprintf("• Theme extraction needs %d more events\n", d.eventsUntilTheme)
	}
	
	if connReady {
		content += readyStyle.Render("• Connection finding ready") + "\n"
	} else {
		content += fmt.Sprintf("• Connection finding needs %d more events\n", d.eventsUntilConn)
	}
	
	if pattReady {
		content += readyStyle.Render("• Pattern analysis ready") + "\n"
	} else {
		content += fmt.Sprintf("• Pattern analysis needs %d more events\n", d.eventsUntilPatt)
	}
	
	return content
}

func (m model) renderCapture() string {
	content := headerStyle.Render("CAPTURE EVENT") + "\n\n"
	content += "Event capture form coming soon...\n"
	content += "For now, use the capture tool directly."
	
	return content
}

func (m model) renderHelp() string {
	var help string
	
	switch m.currentScreen {
	case dashboardScreen:
		help = "Navigation: [1-5] Screens • Actions: [R] Review • [T] Triggers • [X] fx • [K] KG • [F] Refresh • [Q] Quit"
	case searchScreen:
		if m.inputMode {
			help = "Input: Type search term • [Enter] Search • [Esc] Cancel • [Backspace] Delete"
		} else {
			help = "Navigation: [1-5] Screens • Search: [Enter] Start • [Q] Quit"
		}
	case processScreen:
		help = "Navigation: [1-5] Screens • [F] Refresh • [Q] Quit"
	default:
		help = "Navigation: [1-5] Screens • [Q] Quit"
	}
	
	return helpStyle.Render(help)
}

func main() {
	// Check for help flag
	if len(os.Args) > 1 && (os.Args[1] == "--help" || os.Args[1] == "-h") {
		fmt.Println("Usage: ksd [options]")
		fmt.Println("")
		fmt.Println("Interactive TUI dashboard for the Knowledge System")
		fmt.Println("")
		fmt.Println("Options:")
		fmt.Println("  --status, -s    Show current status (non-interactive)")
		fmt.Println("  --help, -h      Show this help message")
		fmt.Println("")
		fmt.Println("Interactive Mode Navigation:")
		fmt.Println("  1/D - Dashboard    2/S - Search      3/A - Analytics")
		fmt.Println("  4/P - Processes    5/C - Capture     Q - Quit")
		fmt.Println("")
		fmt.Println("Dashboard Actions:")
		fmt.Println("  R - Review findings     T - Check triggers")
		fmt.Println("  X - fx JSON viewer      K - KG stats")
		fmt.Println("  F - Refresh")
		return
	}

	// Check for status flag
	if len(os.Args) > 1 && (os.Args[1] == "--status" || os.Args[1] == "-s") {
		// Simple built-in status mode
		_, err := config.LoadKSEnv()
		if err != nil {
			log.Fatal(err)
		}
		
		// Get basic stats
		cmd := exec.Command("bash", "-c", "source .ks-env; source $KS_ROOT/lib/core.sh; source $KS_ROOT/lib/events.sh; ks_count_new_events")
		output, err := cmd.Output()
		if err != nil {
			log.Fatal(err)
		}
		
		totalEvents, _ := strconv.Atoi(strings.TrimSpace(string(output)))
		
		fmt.Println("Knowledge System Status")
		fmt.Println("────────────────────────")
		fmt.Printf("Captured Events: %d\n", totalEvents)
		fmt.Println("Interactive TUI: ./ksd (no arguments)")
		return
	}

	p := tea.NewProgram(initialModel(), tea.WithAltScreen())
	if _, err := p.Run(); err != nil {
		log.Fatal(err)
	}
}