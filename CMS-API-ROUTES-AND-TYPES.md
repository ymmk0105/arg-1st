# CMS API Routes And Types

最終更新: 2026-03-27

## 目的

CMS API のルーティング一覧と request / response の型定義を整理する。

この文書の役割:

- Workers 実装時の入口を明確にする
- 各APIの I/O を揃える
- フロント実装とバックエンド実装の認識を合わせる

---

## 基本ルール

### ベースパス

```text
/api
```

### 認証

- `POST /api/auth/login` を除き認証必須

### データ形式

- request / response は JSON

### 命名方針

- パスは複数形リソースを基本とする
- URL パラメータは `:argId` など camelCase で表記
- JSON キーは camelCase

---

## 共通型

## SuccessResponse

```ts
type SuccessResponse<T> = {
  ok: true;
  data: T;
};
```

## ErrorResponse

```ts
type ErrorResponse = {
  ok: false;
  error: {
    code: string;
    message: string;
    details?: unknown;
  };
};
```

## ApiResponse

```ts
type ApiResponse<T> = SuccessResponse<T> | ErrorResponse;
```

## UserRole

```ts
type UserRole = "admin" | "editor" | "reviewer";
```

## UserStatus

```ts
type UserStatus = "active" | "invited" | "disabled";
```

## ArgStatus

```ts
type ArgStatus = "draft" | "review" | "published" | "archived";
```

## PublishStatus

```ts
type PublishStatus = "pending" | "building" | "published" | "failed" | "rolled_back";
```

## PuzzleType

```ts
type PuzzleType = "acrostic" | "sort" | "hidden-link" | "input-code";
```

## AnswerMode

```ts
type AnswerMode = "single" | "multiple" | "link-only";
```

---

## 共通DTO

## UserDto

```ts
type UserDto = {
  id: string;
  email: string;
  displayName: string;
  role: UserRole;
  status: UserStatus;
  createdAt: string;
  updatedAt: string;
  lastLoginAt?: string | null;
};
```

## ArgSummaryDto

```ts
type ArgSummaryDto = {
  id: string;
  title: string;
  subtitle?: string | null;
  slug: string;
  status: ArgStatus;
  storyReady: boolean;
  puzzleCount: number;
  enabledPuzzleCount: number;
  currentPublishedSnapshotId?: string | null;
  lastPublishedAt?: string | null;
  updatedAt: string;
};
```

## ArgDetailDto

```ts
type ArgDetailDto = {
  id: string;
  title: string;
  subtitle?: string | null;
  summary?: string | null;
  slug: string;
  status: ArgStatus;
  genre?: string | null;
  difficulty?: number | null;
  estimatedMinutes?: number | null;
  storyReady: boolean;
  puzzleCount: number;
  enabledPuzzleCount: number;
  currentPublishedSnapshotId?: string | null;
  firstPublishedAt?: string | null;
  lastPublishedAt?: string | null;
  createdAt: string;
  updatedAt: string;
};
```

## StoryRevisionDto

```ts
type StoryRevisionDto = {
  id: string;
  revisionNumber: number;
  title: string;
  worldOverview: unknown[];
  playerRole: unknown[];
  characters: unknown[];
  progression: unknown[];
  endings: unknown[];
  atmosphere: unknown[];
  authorNote?: string | null;
  changeSummary?: string | null;
  createdAt: string;
  createdBy?: string | null;
};
```

## PuzzleDto

```ts
type PuzzleDto = {
  id: string;
  puzzleKey: string;
  title: string;
  displayOrder: number;
  puzzleType: PuzzleType;
  isEnabled: boolean;
  currentRevisionId?: string | null;
  latestRevisionNumber: number;
  updatedAt: string;
};
```

## PuzzleRevisionDto

```ts
type PuzzleRevisionDto = {
  id: string;
  revisionNumber: number;
  title: string;
  objective?: string | null;
  locationPageKey?: string | null;
  problemText?: string | null;
  displayContent: unknown;
  hints: unknown[];
  answerMode: AnswerMode;
  acceptedAnswers: string[];
  solutionText?: string | null;
  nextAction?: unknown;
  uiConfig?: unknown;
  validationRule?: unknown;
  authorNote?: string | null;
  changeSummary?: string | null;
  isRequired: boolean;
  createdAt: string;
  createdBy?: string | null;
};
```

## PublishCheckItemDto

```ts
type PublishCheckItemDto = {
  key: string;
  status: "ok" | "warning" | "error";
  message: string;
};
```

## PublishCheckDto

```ts
type PublishCheckDto = {
  canPublish: boolean;
  checks: PublishCheckItemDto[];
  storyRevisionId?: string | null;
  puzzleRevisionIds: string[];
};
```

## PublishHistoryItemDto

```ts
type PublishHistoryItemDto = {
  snapshotId: string;
  snapshotVersion: number;
  publishStatus: PublishStatus;
  publishedAt?: string | null;
  deployedUrl?: string | null;
};
```

## TemplateDto

```ts
type TemplateDto = {
  key: string;
  title: string;
  description?: string | null;
  body: unknown;
};
```

---

## ルーティング一覧

## 認証

| method | path | auth | role |
|---|---|---:|---|
| POST | `/api/auth/login` | no | public |
| POST | `/api/auth/logout` | yes | all |
| GET | `/api/auth/me` | yes | all |

## 作品管理

| method | path | auth | role |
|---|---|---:|---|
| GET | `/api/args` | yes | all |
| POST | `/api/args` | yes | admin, editor |
| GET | `/api/args/:argId` | yes | all |
| PATCH | `/api/args/:argId` | yes | admin, editor |
| GET | `/api/args/:argId/publish-check` | yes | admin, reviewer |
| POST | `/api/args/:argId/publish` | yes | admin |
| GET | `/api/args/:argId/publish-history` | yes | all |

## ストーリー管理

| method | path | auth | role |
|---|---|---:|---|
| GET | `/api/args/:argId/story` | yes | all |
| POST | `/api/args/:argId/story/revisions` | yes | admin, editor |
| GET | `/api/args/:argId/story/revisions` | yes | all |
| GET | `/api/args/:argId/story/revisions/:revisionId` | yes | all |

## パズル管理

| method | path | auth | role |
|---|---|---:|---|
| GET | `/api/args/:argId/puzzles` | yes | all |
| POST | `/api/args/:argId/puzzles` | yes | admin, editor |
| GET | `/api/args/:argId/puzzles/:puzzleId` | yes | all |
| PATCH | `/api/args/:argId/puzzles/:puzzleId` | yes | admin, editor |
| POST | `/api/args/:argId/puzzles/:puzzleId/revisions` | yes | admin, editor |
| GET | `/api/args/:argId/puzzles/:puzzleId/revisions` | yes | all |
| GET | `/api/args/:argId/puzzles/:puzzleId/revisions/:revisionId` | yes | all |

## ユーザー管理

| method | path | auth | role |
|---|---|---:|---|
| GET | `/api/users` | yes | admin |
| POST | `/api/users` | yes | admin |
| PATCH | `/api/users/:userId` | yes | admin |
| PATCH | `/api/users/:userId/password` | yes | admin |

## テンプレ

| method | path | auth | role |
|---|---|---:|---|
| GET | `/api/templates/story` | yes | all |
| GET | `/api/templates/puzzles` | yes | all |

---

## 認証API 型定義

## `POST /api/auth/login`

### Request

```ts
type LoginRequest = {
  email: string;
  password: string;
};
```

### Response

```ts
type LoginResponse = ApiResponse<{
  user: UserDto;
}>;
```

---

## `POST /api/auth/logout`

### Request

```ts
type LogoutRequest = {};
```

### Response

```ts
type LogoutResponse = ApiResponse<{
  loggedOut: true;
}>;
```

---

## `GET /api/auth/me`

### Response

```ts
type MeResponse = ApiResponse<{
  user: UserDto;
}>;
```

---

## 作品管理 API 型定義

## `GET /api/args`

### Query

```ts
type ListArgsQuery = {
  status?: ArgStatus;
  q?: string;
};
```

### Response

```ts
type ListArgsResponse = ApiResponse<{
  items: ArgSummaryDto[];
}>;
```

---

## `POST /api/args`

### Request

```ts
type CreateArgRequest = {
  title: string;
  subtitle?: string;
  summary?: string;
  slug: string;
  genre?: string;
  difficulty?: number;
  estimatedMinutes?: number;
};
```

### Response

```ts
type CreateArgResponse = ApiResponse<{
  arg: ArgDetailDto;
}>;
```

---

## `GET /api/args/:argId`

### Response

```ts
type GetArgResponse = ApiResponse<{
  arg: ArgDetailDto;
}>;
```

---

## `PATCH /api/args/:argId`

### Request

```ts
type UpdateArgRequest = Partial<{
  title: string;
  subtitle: string;
  summary: string;
  slug: string;
  genre: string;
  difficulty: number;
  estimatedMinutes: number;
  status: ArgStatus;
}>;
```

### Response

```ts
type UpdateArgResponse = ApiResponse<{
  arg: ArgDetailDto;
}>;
```

---

## `GET /api/args/:argId/publish-check`

### Response

```ts
type PublishCheckResponse = ApiResponse<PublishCheckDto>;
```

---

## `POST /api/args/:argId/publish`

### Request

```ts
type PublishArgRequest = {
  confirm: true;
};
```

### Response

```ts
type PublishArgResponse = ApiResponse<{
  snapshotId: string;
  publishJobId: string;
  status: "queued" | "running";
}>;
```

---

## `GET /api/args/:argId/publish-history`

### Response

```ts
type PublishHistoryResponse = ApiResponse<{
  items: PublishHistoryItemDto[];
}>;
```

---

## ストーリー管理 API 型定義

## `GET /api/args/:argId/story`

### Response

```ts
type GetStoryResponse = ApiResponse<{
  storyId: string | null;
  currentRevision: StoryRevisionDto | null;
}>;
```

---

## `POST /api/args/:argId/story/revisions`

### Request

```ts
type CreateStoryRevisionRequest = {
  title: string;
  worldOverview: unknown[];
  playerRole: unknown[];
  characters: unknown[];
  progression: unknown[];
  endings: unknown[];
  atmosphere: unknown[];
  authorNote?: string;
  changeSummary?: string;
};
```

### Response

```ts
type CreateStoryRevisionResponse = ApiResponse<{
  revision: StoryRevisionDto;
}>;
```

---

## `GET /api/args/:argId/story/revisions`

### Response

```ts
type ListStoryRevisionsResponse = ApiResponse<{
  items: StoryRevisionDto[];
}>;
```

---

## `GET /api/args/:argId/story/revisions/:revisionId`

### Response

```ts
type GetStoryRevisionResponse = ApiResponse<{
  revision: StoryRevisionDto;
}>;
```

---

## パズル管理 API 型定義

## `GET /api/args/:argId/puzzles`

### Response

```ts
type ListPuzzlesResponse = ApiResponse<{
  items: PuzzleDto[];
}>;
```

---

## `POST /api/args/:argId/puzzles`

### Request

```ts
type CreatePuzzleRequest = {
  puzzleKey: string;
  title: string;
  displayOrder: number;
  puzzleType: PuzzleType;
};
```

### Response

```ts
type CreatePuzzleResponse = ApiResponse<{
  puzzle: PuzzleDto;
}>;
```

---

## `GET /api/args/:argId/puzzles/:puzzleId`

### Response

```ts
type GetPuzzleResponse = ApiResponse<{
  puzzle: PuzzleDto;
}>;
```

---

## `PATCH /api/args/:argId/puzzles/:puzzleId`

### Request

```ts
type UpdatePuzzleRequest = Partial<{
  title: string;
  displayOrder: number;
  puzzleType: PuzzleType;
  isEnabled: boolean;
}>;
```

### Response

```ts
type UpdatePuzzleResponse = ApiResponse<{
  puzzle: PuzzleDto;
}>;
```

---

## `POST /api/args/:argId/puzzles/:puzzleId/revisions`

### Request

```ts
type CreatePuzzleRevisionRequest = {
  title: string;
  objective?: string;
  locationPageKey?: string;
  problemText?: string;
  displayContent: unknown;
  hints: unknown[];
  answerMode: AnswerMode;
  acceptedAnswers: string[];
  solutionText?: string;
  nextAction?: unknown;
  uiConfig?: unknown;
  validationRule?: unknown;
  authorNote?: string;
  changeSummary?: string;
  isRequired: boolean;
};
```

### Response

```ts
type CreatePuzzleRevisionResponse = ApiResponse<{
  revision: PuzzleRevisionDto;
}>;
```

---

## `GET /api/args/:argId/puzzles/:puzzleId/revisions`

### Response

```ts
type ListPuzzleRevisionsResponse = ApiResponse<{
  items: PuzzleRevisionDto[];
}>;
```

---

## `GET /api/args/:argId/puzzles/:puzzleId/revisions/:revisionId`

### Response

```ts
type GetPuzzleRevisionResponse = ApiResponse<{
  revision: PuzzleRevisionDto;
}>;
```

---

## ユーザー管理 API 型定義

## `GET /api/users`

### Response

```ts
type ListUsersResponse = ApiResponse<{
  items: UserDto[];
}>;
```

---

## `POST /api/users`

### Request

```ts
type CreateUserRequest = {
  email: string;
  displayName: string;
  password: string;
  role: UserRole;
  status: UserStatus;
};
```

### Response

```ts
type CreateUserResponse = ApiResponse<{
  user: UserDto;
}>;
```

---

## `PATCH /api/users/:userId`

### Request

```ts
type UpdateUserRequest = Partial<{
  displayName: string;
  role: UserRole;
  status: UserStatus;
}>;
```

### Response

```ts
type UpdateUserResponse = ApiResponse<{
  user: UserDto;
}>;
```

---

## `PATCH /api/users/:userId/password`

### Request

```ts
type ResetUserPasswordRequest = {
  password: string;
};
```

### Response

```ts
type ResetUserPasswordResponse = ApiResponse<{
  updated: true;
}>;
```

---

## テンプレ API 型定義

## `GET /api/templates/story`

### Response

```ts
type GetStoryTemplatesResponse = ApiResponse<{
  items: TemplateDto[];
}>;
```

---

## `GET /api/templates/puzzles`

### Response

```ts
type GetPuzzleTemplatesResponse = ApiResponse<{
  items: TemplateDto[];
}>;
```

---

## エラーコード案

```ts
type ApiErrorCode =
  | "UNAUTHORIZED"
  | "FORBIDDEN"
  | "NOT_FOUND"
  | "VALIDATION_ERROR"
  | "CONFLICT"
  | "PUBLISH_CHECK_FAILED"
  | "INTERNAL_ERROR";
```

---

## まとめ

この文書では、

- ルーティング一覧
- 認証要件
- 権限制御
- request / response 型
- 共通DTO

を Workers 実装に使える粒度で整理した。
