package events

import (
	"bufio"
	"encoding/json"
	"fmt"
	"os"
	"time"
)

// Event represents a knowledge system event
type Event struct {
	Timestamp string `json:"timestamp"`
	Type      string `json:"type"`
	Content   string `json:"content"`
	Tags      string `json:"tags,omitempty"`
}

// Reader reads events from JSONL files
type Reader struct {
	file    *os.File
	scanner *bufio.Scanner
}

// NewReader creates a new event reader for the given file
func NewReader(filename string) (*Reader, error) {
	file, err := os.Open(filename)
	if err != nil {
		return nil, fmt.Errorf("opening file: %w", err)
	}

	return &Reader{
		file:    file,
		scanner: bufio.NewScanner(file),
	}, nil
}

// Close closes the underlying file
func (r *Reader) Close() error {
	return r.file.Close()
}

// Next reads the next event from the file
func (r *Reader) Next() (*Event, error) {
	if !r.scanner.Scan() {
		if err := r.scanner.Err(); err != nil {
			return nil, fmt.Errorf("scanning: %w", err)
		}
		return nil, nil // EOF
	}

	var event Event
	if err := json.Unmarshal(r.scanner.Bytes(), &event); err != nil {
		return nil, fmt.Errorf("parsing JSON: %w", err)
	}

	return &event, nil
}

// ReadAll reads all events from a file
func ReadAll(filename string) ([]*Event, error) {
	reader, err := NewReader(filename)
	if err != nil {
		return nil, err
	}
	defer reader.Close()

	var events []*Event
	for {
		event, err := reader.Next()
		if err != nil {
			return nil, err
		}
		if event == nil {
			break
		}
		events = append(events, event)
	}

	return events, nil
}

// FormatTime formats the event timestamp for display
func (e *Event) FormatTime() string {
	// Try parsing the timestamp
	t, err := time.Parse("2006-01-02T15:04:05Z07:00", e.Timestamp)
	if err != nil {
		return e.Timestamp
	}
	return t.Format("2006-01-02 15:04")
}