-- 初期管理者ユーザ投入用 seed
-- 実運用では password_hash をハッシュ済みの値に置き換えてから適用すること

INSERT INTO users (
  id,
  email,
  display_name,
  role,
  status,
  password_hash,
  password_updated_at,
  last_login_at,
  failed_login_count,
  created_at,
  updated_at
) VALUES (
  '00000000-0000-4000-8000-000000000001',
  'admin@example.com',
  'Initial Admin',
  'admin',
  'active',
  'REPLACE_WITH_HASHED_PASSWORD',
  '2026-03-27T00:00:00Z',
  NULL,
  0,
  '2026-03-27T00:00:00Z',
  '2026-03-27T00:00:00Z'
);
