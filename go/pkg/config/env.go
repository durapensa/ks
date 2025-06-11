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
}

// LoadKSEnv reads the .ks-env file and returns configuration
func LoadKSEnv() (*Config, error) {
	// Find project root by looking for .ks-env
	root, err := findProjectRoot()
	if err != nil {
		return nil, fmt.Errorf("finding project root: %w", err)
	}

	envFile := filepath.Join(root, ".ks-env")
	file, err := os.Open(envFile)
	if err != nil {
		return nil, fmt.Errorf("opening .ks-env: %w", err)
	}
	defer file.Close()

	config := &Config{
		KSRoot: root,
	}

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
					config.KnowledgeDir = value
				case "KS_EVENTS_DIR":
					config.EventsDir = value
				case "KS_HOT_LOG":
					config.HotLog = value
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