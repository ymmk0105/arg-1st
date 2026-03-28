PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  display_name TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('admin', 'editor', 'reviewer')),
  status TEXT NOT NULL CHECK (status IN ('active', 'invited', 'disabled')),
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS args (
  id TEXT PRIMARY KEY,
  slug TEXT NOT NULL UNIQUE,
  title TEXT NOT NULL,
  subtitle TEXT,
  summary TEXT,
  status TEXT NOT NULL CHECK (status IN ('draft', 'review', 'published', 'archived')),
  genre TEXT,
  difficulty INTEGER CHECK (difficulty IS NULL OR difficulty BETWEEN 1 AND 5),
  estimated_minutes INTEGER CHECK (estimated_minutes IS NULL OR estimated_minutes >= 0),
  cover_asset_id TEXT,
  current_story_revision_id TEXT,
  current_published_snapshot_id TEXT,
  first_published_at TEXT,
  last_published_at TEXT,
  created_by TEXT,
  updated_by TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
  FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_args_status ON args(status);
CREATE INDEX IF NOT EXISTS idx_args_last_published_at ON args(last_published_at);

CREATE TABLE IF NOT EXISTS stories (
  id TEXT PRIMARY KEY,
  arg_id TEXT NOT NULL UNIQUE,
  current_revision_id TEXT,
  latest_revision_number INTEGER NOT NULL DEFAULT 0,
  created_by TEXT,
  updated_by TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (arg_id) REFERENCES args(id) ON DELETE CASCADE,
  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
  FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS story_revisions (
  id TEXT PRIMARY KEY,
  story_id TEXT NOT NULL,
  revision_number INTEGER NOT NULL,
  title TEXT NOT NULL,
  world_overview_json TEXT,
  player_role_json TEXT,
  characters_json TEXT,
  progression_json TEXT,
  endings_json TEXT,
  atmosphere_json TEXT,
  author_note TEXT,
  change_summary TEXT,
  is_published_source INTEGER NOT NULL DEFAULT 0 CHECK (is_published_source IN (0, 1)),
  created_by TEXT,
  created_at TEXT NOT NULL,
  FOREIGN KEY (story_id) REFERENCES stories(id) ON DELETE CASCADE,
  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
  UNIQUE (story_id, revision_number)
);

CREATE INDEX IF NOT EXISTS idx_story_revisions_created_at ON story_revisions(created_at);

CREATE TABLE IF NOT EXISTS puzzles (
  id TEXT PRIMARY KEY,
  arg_id TEXT NOT NULL,
  puzzle_key TEXT NOT NULL,
  display_order INTEGER NOT NULL,
  puzzle_type TEXT NOT NULL,
  current_revision_id TEXT,
  latest_revision_number INTEGER NOT NULL DEFAULT 0,
  created_by TEXT,
  updated_by TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (arg_id) REFERENCES args(id) ON DELETE CASCADE,
  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
  FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL,
  UNIQUE (arg_id, puzzle_key),
  UNIQUE (arg_id, display_order)
);

CREATE TABLE IF NOT EXISTS puzzle_revisions (
  id TEXT PRIMARY KEY,
  puzzle_id TEXT NOT NULL,
  revision_number INTEGER NOT NULL,
  title TEXT NOT NULL,
  objective TEXT,
  location_page_key TEXT,
  problem_text TEXT,
  display_content_json TEXT,
  hints_json TEXT,
  answer_mode TEXT NOT NULL CHECK (answer_mode IN ('single', 'multiple', 'link-only')),
  accepted_answers_json TEXT,
  solution_text TEXT,
  next_action_json TEXT,
  ui_config_json TEXT,
  validation_rule_json TEXT,
  author_note TEXT,
  change_summary TEXT,
  is_required INTEGER NOT NULL DEFAULT 1 CHECK (is_required IN (0, 1)),
  is_published_source INTEGER NOT NULL DEFAULT 0 CHECK (is_published_source IN (0, 1)),
  created_by TEXT,
  created_at TEXT NOT NULL,
  FOREIGN KEY (puzzle_id) REFERENCES puzzles(id) ON DELETE CASCADE,
  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
  UNIQUE (puzzle_id, revision_number)
);

CREATE INDEX IF NOT EXISTS idx_puzzle_revisions_location_page_key ON puzzle_revisions(location_page_key);
CREATE INDEX IF NOT EXISTS idx_puzzle_revisions_created_at ON puzzle_revisions(created_at);

CREATE TABLE IF NOT EXISTS published_snapshots (
  id TEXT PRIMARY KEY,
  arg_id TEXT NOT NULL,
  snapshot_version INTEGER NOT NULL,
  story_revision_id TEXT NOT NULL,
  puzzle_revision_map_json TEXT NOT NULL,
  page_config_json TEXT,
  output_config_json TEXT,
  content_hash TEXT,
  publish_status TEXT NOT NULL CHECK (publish_status IN ('pending', 'building', 'published', 'failed', 'rolled_back')),
  deployed_url TEXT,
  build_log TEXT,
  published_by TEXT,
  published_at TEXT,
  created_at TEXT NOT NULL,
  FOREIGN KEY (arg_id) REFERENCES args(id) ON DELETE CASCADE,
  FOREIGN KEY (story_revision_id) REFERENCES story_revisions(id) ON DELETE RESTRICT,
  FOREIGN KEY (published_by) REFERENCES users(id) ON DELETE SET NULL,
  UNIQUE (arg_id, snapshot_version)
);

CREATE INDEX IF NOT EXISTS idx_published_snapshots_arg_status ON published_snapshots(arg_id, publish_status);
CREATE INDEX IF NOT EXISTS idx_published_snapshots_published_at ON published_snapshots(published_at);

CREATE TABLE IF NOT EXISTS publish_jobs (
  id TEXT PRIMARY KEY,
  arg_id TEXT NOT NULL,
  snapshot_id TEXT NOT NULL,
  job_type TEXT NOT NULL CHECK (job_type IN ('publish', 'rollback', 'rebuild')),
  status TEXT NOT NULL CHECK (status IN ('queued', 'running', 'succeeded', 'failed')),
  requested_by TEXT,
  started_at TEXT,
  finished_at TEXT,
  error_message TEXT,
  log_json TEXT,
  created_at TEXT NOT NULL,
  FOREIGN KEY (arg_id) REFERENCES args(id) ON DELETE CASCADE,
  FOREIGN KEY (snapshot_id) REFERENCES published_snapshots(id) ON DELETE CASCADE,
  FOREIGN KEY (requested_by) REFERENCES users(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_publish_jobs_snapshot_id ON publish_jobs(snapshot_id);
CREATE INDEX IF NOT EXISTS idx_publish_jobs_status ON publish_jobs(status);

CREATE TABLE IF NOT EXISTS audit_logs (
  id TEXT PRIMARY KEY,
  actor_user_id TEXT,
  action_type TEXT NOT NULL,
  target_type TEXT NOT NULL,
  target_id TEXT NOT NULL,
  arg_id TEXT,
  metadata_json TEXT,
  created_at TEXT NOT NULL,
  FOREIGN KEY (actor_user_id) REFERENCES users(id) ON DELETE SET NULL,
  FOREIGN KEY (arg_id) REFERENCES args(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_arg_id ON audit_logs(arg_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_actor_user_id ON audit_logs(actor_user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs(created_at);

CREATE TABLE IF NOT EXISTS assets (
  id TEXT PRIMARY KEY,
  arg_id TEXT NOT NULL,
  file_name TEXT NOT NULL,
  storage_key TEXT NOT NULL,
  mime_type TEXT,
  file_size INTEGER CHECK (file_size IS NULL OR file_size >= 0),
  width INTEGER CHECK (width IS NULL OR width >= 0),
  height INTEGER CHECK (height IS NULL OR height >= 0),
  alt_text TEXT,
  uploaded_by TEXT,
  created_at TEXT NOT NULL,
  FOREIGN KEY (arg_id) REFERENCES args(id) ON DELETE CASCADE,
  FOREIGN KEY (uploaded_by) REFERENCES users(id) ON DELETE SET NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_assets_storage_key ON assets(storage_key);
CREATE INDEX IF NOT EXISTS idx_assets_arg_id ON assets(arg_id);
