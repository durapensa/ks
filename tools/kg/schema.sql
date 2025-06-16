-- SQLite schema for distilled knowledge graph
-- Based on issue #19 specification with minimal, extensible design

-- Core concepts table
CREATE TABLE concepts (
    id TEXT PRIMARY KEY,          -- timestamp-based or content hash
    name TEXT NOT NULL,           -- canonical form
    weight REAL DEFAULT 1.0,      -- overall importance
    human_weight REAL DEFAULT 0,  -- human contribution % (0-1)
    ai_weight REAL DEFAULT 0,     -- AI contribution % (0-1)
    created TEXT NOT NULL,        -- first seen timestamp
    updated TEXT NOT NULL         -- last modified timestamp
);

-- Relationships between concepts
CREATE TABLE edges (
    source_id TEXT NOT NULL,
    target_id TEXT NOT NULL,
    edge_type TEXT NOT NULL,      -- 'relates', 'causes', 'contradicts', etc.
    strength REAL DEFAULT 1.0,    -- relationship strength (0-1)
    created TEXT NOT NULL,
    PRIMARY KEY (source_id, target_id, edge_type),
    FOREIGN KEY (source_id) REFERENCES concepts(id),
    FOREIGN KEY (target_id) REFERENCES concepts(id)
);

-- Aliases for concept variations
CREATE TABLE aliases (
    canonical_id TEXT NOT NULL,
    alias TEXT NOT NULL,
    source TEXT,                  -- where this variant was seen
    count INTEGER DEFAULT 1,      -- usage frequency
    PRIMARY KEY (canonical_id, alias),
    FOREIGN KEY (canonical_id) REFERENCES concepts(id)
);

-- Performance indexes
CREATE INDEX idx_concepts_name ON concepts(name);
CREATE INDEX idx_concepts_weight ON concepts(weight DESC);
CREATE INDEX idx_edges_source ON edges(source_id);
CREATE INDEX idx_edges_target ON edges(target_id);

-- Metadata table for tracking distillation runs
CREATE TABLE distillation_runs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    started_at TEXT NOT NULL,
    completed_at TEXT,
    events_processed INTEGER DEFAULT 0,
    concepts_extracted INTEGER DEFAULT 0,
    edges_created INTEGER DEFAULT 0,
    status TEXT DEFAULT 'running'  -- 'running', 'completed', 'failed'
);