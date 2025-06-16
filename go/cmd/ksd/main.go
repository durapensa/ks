package main

import (
	"fmt"
	"log"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"time"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/durapensa/ks/pkg/config"
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

// Dashboard data
type dashboardData struct {
	totalEvents       int
	pendingCount      int
	activeProcesses   int
	eventsUntilTheme  int
	eventsUntilConn   int
	eventsUntilPatt   int
	lastUpdate        string
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
		loadDashboardData,
		tea.Every(time.Second*30, func(time.Time) tea.Msg {
			return loadDashboardData()
		}),
	)
}

// Load dashboard data from system
func loadDashboardData() tea.Msg {
	// Get event count
	cmd := exec.Command("bash", "-c", "source ~/.ks-env 2>/dev/null || source .ks-env; source $KS_ROOT/lib/core.sh; source $KS_ROOT/lib/events.sh; ks_count_new_events")
	output, err := cmd.Output()
	if err != nil {
		return errorMsg{fmt.Errorf("counting events: %w", err)}
	}
	
	totalEvents, _ := strconv.Atoi(strings.TrimSpace(string(output)))

	// Get pending analyses count
	cmd = exec.Command("bash", "-c", "source ~/.ks-env 2>/dev/null || source .ks-env; source $KS_ROOT/lib/core.sh; source $KS_ROOT/tools/lib/queue.sh; ks_queue_list_pending | jq 'length'")
	output, err = cmd.Output()
	if err == nil {
		pendingCount, _ := strconv.Atoi(strings.TrimSpace(string(output)))
		
		return dashboardMsg{
			data: dashboardData{
				totalEvents:     totalEvents,
				pendingCount:    pendingCount,
				activeProcesses: 0, // TODO: implement
				eventsUntilTheme: 10 - (totalEvents % 10),
				eventsUntilConn:  20 - (totalEvents % 20),
				eventsUntilPatt:  30 - (totalEvents % 30),
				lastUpdate:      time.Now().Format("15:04:05"),
			},
		}
	}

	return dashboardMsg{
		data: dashboardData{
			totalEvents:     totalEvents,
			pendingCount:    0,
			activeProcesses: 0,
			eventsUntilTheme: 10 - (totalEvents % 10),
			eventsUntilConn:  20 - (totalEvents % 20),
			eventsUntilPatt:  30 - (totalEvents % 30),
			lastUpdate:      time.Now().Format("15:04:05"),
		},
	}
}

// Handle external tool execution
func runExternalTool(tool string, args ...string) tea.Cmd {
	cmd := exec.Command(tool, args...)
	return tea.ExecProcess(cmd, func(err error) tea.Msg {
		if err != nil {
			return errorMsg{fmt.Errorf("running %s: %w", tool, err)}
		}
		return loadDashboardData()
	})
}

// Search knowledge base
func searchKnowledge(term string) tea.Cmd {
	return func() tea.Msg {
		cmd := exec.Command("bash", "-c", fmt.Sprintf("source ~/.ks-env 2>/dev/null || source .ks-env; $KS_ROOT/tools/capture/query '%s'", term))
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
				return m, runExternalTool("bash", "-c", "source ~/.ks-env 2>/dev/null || source .ks-env; $KS_ROOT/tools/introspect/review-findings")
			}
		case "t":
			if m.currentScreen == dashboardScreen {
				return m, runExternalTool("bash", "-c", "source ~/.ks-env 2>/dev/null || source .ks-env; $KS_ROOT/tools/plumbing/check-event-triggers --verbose")
			}
		case "x":
			// Launch fx viewer for knowledge exploration
			return m, runExternalTool("bash", "-c", "source ~/.ks-env 2>/dev/null || source .ks-env; fx $KS_HOT_LOG")
		case "k":
			// Quick kg query
			if m.currentScreen == dashboardScreen {
				return m, runExternalTool("bash", "-c", "source ~/.ks-env 2>/dev/null || source .ks-env; $KS_ROOT/tools/kg/query --stats")
			}
		case "f":
			return m, loadDashboardData
			
		// Search actions
		case "enter":
			if m.currentScreen == searchScreen {
				if m.inputMode {
					m.inputMode = false
					m.searchTerm = m.searchInput
					return m, searchKnowledge(m.searchInput)
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
	}

	return m, nil
}

func (m model) View() string {
	if m.error != nil {
		return fmt.Sprintf("Error: %v\n\nPress q to quit.", m.error)
	}

	// Title
	title := titleStyle.Width(80).Render("KNOWLEDGE SYSTEM DASHBOARD")
	
	// Navigation breadcrumb
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
	
	nav := statusStyle.Render(fmt.Sprintf("Current: %s", breadcrumb))
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

	return fmt.Sprintf("%s\n%s\n%s\n\n%s\n\n%s", title, nav, separator, content, help)
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

	// Pending reviews
	pending := ""
	if d.pendingCount > 0 {
		pending = separatorStyle.Render(strings.Repeat("─", 80)) + "\n"
		pending += "PENDING REVIEWS:\n"
		pending += fmt.Sprintf("  %d analysis/analyses ready for review", d.pendingCount)
	}

	return fmt.Sprintf("%s\n%s\n%s\n%s", status, separatorStyle.Render(strings.Repeat("─", 80)), triggers, pending)
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