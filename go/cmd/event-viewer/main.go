package main

import (
	"fmt"
	"log"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/durapensa/ks/pkg/config"
	"github.com/durapensa/ks/pkg/events"
)

var (
	titleStyle = lipgloss.NewStyle().
			Bold(true).
			Foreground(lipgloss.Color("205")).
			MarginBottom(1)

	selectedStyle = lipgloss.NewStyle().
			Background(lipgloss.Color("237")).
			Foreground(lipgloss.Color("255"))

	normalStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("252"))

	helpStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("241")).
			MarginTop(1)
)

type model struct {
	events   []*events.Event
	selected int
	width    int
	height   int
	error    error
}

func initialModel() model {
	return model{
		events:   []*events.Event{},
		selected: 0,
	}
}

func (m model) Init() tea.Cmd {
	return loadEvents
}

func loadEvents() tea.Msg {
	cfg, err := config.LoadKSEnv()
	if err != nil {
		return errMsg{err}
	}

	// Try to read hot.jsonl
	hotLog := cfg.HotLog
	if hotLog == "" {
		hotLog = "knowledge/events/hot.jsonl"
	}

	eventList, err := events.ReadAll(hotLog)
	if err != nil {
		// Try fallback path
		eventList, err = events.ReadAll("knowledge/events/hot.jsonl")
		if err != nil {
			return errMsg{fmt.Errorf("reading events: %w", err)}
		}
	}

	return eventsMsg{eventList}
}

type eventsMsg struct {
	events []*events.Event
}

type errMsg struct {
	err error
}

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "ctrl+c", "q":
			return m, tea.Quit
		case "up", "k":
			if m.selected > 0 {
				m.selected--
			}
		case "down", "j":
			if m.selected < len(m.events)-1 {
				m.selected++
			}
		}

	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height

	case eventsMsg:
		m.events = msg.events

	case errMsg:
		m.error = msg.err
	}

	return m, nil
}

func (m model) View() string {
	if m.error != nil {
		return fmt.Sprintf("Error: %v\n\nPress q to quit.", m.error)
	}

	s := titleStyle.Render("Knowledge System Event Viewer") + "\n\n"

	if len(m.events) == 0 {
		s += "No events found.\n"
	} else {
		// Show events with selection
		visibleEvents := 10
		if m.height > 0 {
			visibleEvents = m.height - 8 // Leave room for title and help
		}

		start := 0
		if m.selected >= visibleEvents {
			start = m.selected - visibleEvents + 1
		}

		for i := start; i < len(m.events) && i < start+visibleEvents; i++ {
			event := m.events[i]
			line := fmt.Sprintf("%s | %-8s | %s",
				event.FormatTime(),
				event.Type,
				truncate(event.Content, 60))

			if i == m.selected {
				s += selectedStyle.Render(line) + "\n"
			} else {
				s += normalStyle.Render(line) + "\n"
			}
		}
	}

	s += helpStyle.Render("\n↑/↓: navigate • q: quit")
	return s
}

func truncate(s string, max int) string {
	if len(s) <= max {
		return s
	}
	return s[:max-3] + "..."
}

func main() {
	// Simple integration test message
	fmt.Println("Testing Go integration with knowledge system...")
	fmt.Println("Loading events from hot.jsonl...\n")

	p := tea.NewProgram(initialModel())
	if _, err := p.Run(); err != nil {
		log.Fatal(err)
	}
}