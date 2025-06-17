package config

import (
	"bufio"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

// Config holds the knowledge system configuration
type Config struct {
	KSRoot         string
	KnowledgeDir   string
	EventsDir      string
	HotLog         string
	Model          string
	IsConversation bool
	ConversationDir string
	ContextName    string
}

// LoadKSEnv reads the .ks-env file and returns configuration
func LoadKSEnv() (*Config, error) {
	// Find project root by looking for .ks-env
	root, err := findProjectRoot()
	if err != nil {
		return nil, fmt.Errorf("finding project root: %w", err)
	}

	// Check if we're in a conversation directory
	currentDir, err := os.Getwd()
	if err != nil {
		return nil, fmt.Errorf("getting current directory: %w", err)
	}

	config := &Config{
		KSRoot: root,
	}

	// Detect conversation context
	localKnowledgeDir := filepath.Join(currentDir, "knowledge")
	conversationConfig := filepath.Join(currentDir, "logex-config.yaml")
	
	// A conversation directory has ./knowledge/ AND logex-config.yaml
	// This distinguishes experiment directories from the main ks directory
	if stat, err := os.Stat(localKnowledgeDir); err == nil && stat.IsDir() {
		if _, err := os.Stat(conversationConfig); err == nil {
			// We're in a conversation/experiment directory
			config.IsConversation = true
			config.ConversationDir = currentDir
			config.ContextName = filepath.Base(currentDir)
			config.KnowledgeDir = localKnowledgeDir
			config.EventsDir = filepath.Join(localKnowledgeDir, "events")
			config.HotLog = filepath.Join(config.EventsDir, "hot.jsonl")
		}
	}

	// Load environment file
	envFile := filepath.Join(root, ".ks-env")
	file, err := os.Open(envFile)
	if err != nil {
		return nil, fmt.Errorf("opening .ks-env: %w", err)
	}
	defer file.Close()

	// Parse shell environment variables
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		
		// Skip comments and empty lines
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}

		// Parse export statements
		if strings.HasPrefix(line, "export ") {
			line = strings.TrimPrefix(line, "export ")
			parts := strings.SplitN(line, "=", 2)
			if len(parts) == 2 {
				key := parts[0]
				value := strings.Trim(parts[1], `"'`)
				
				// Expand variables like $KS_ROOT
				value = os.Expand(value, func(v string) string {
					switch v {
					case "KS_ROOT":
						return config.KSRoot
					default:
						return os.Getenv(v)
					}
				})

				switch key {
				case "KS_KNOWLEDGE_DIR":
					if !config.IsConversation {
						config.KnowledgeDir = value
					}
				case "KS_EVENTS_DIR":
					if !config.IsConversation {
						config.EventsDir = value
					}
				case "KS_HOT_LOG":
					if !config.IsConversation {
						config.HotLog = value
					}
				case "KS_MODEL":
					config.Model = value
				}
			}
		}
	}

	// Apply environment overrides
	if val := os.Getenv("KS_MODEL"); val != "" {
		config.Model = val
	}

	return config, scanner.Err()
}

func findProjectRoot() (string, error) {
	// Start from current directory and walk up
	dir, err := os.Getwd()
	if err != nil {
		return "", err
	}

	for {
		if _, err := os.Stat(filepath.Join(dir, ".ks-env")); err == nil {
			return dir, nil
		}

		parent := filepath.Dir(dir)
		if parent == dir {
			break
		}
		dir = parent
	}

	return "", fmt.Errorf(".ks-env not found")
}