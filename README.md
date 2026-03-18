# NexLearn

NexLearn is a full-stack learning app with two interactive lesson types:

- `Chemistry`: a reaction-rate simulator that updates a concentration-decay chart as the learner changes concentration and temperature.
- `English`: a sentence analyzer that highlights the detected subject, verb, and object in real time.

The repository contains a Flutter Web frontend and a FastAPI backend. The backend seeds the lesson data automatically on startup, so the app is usable without manual database setup.

## What The App Does

1. The Flutter app starts on a subject chooser screen.
2. The user opens either `Chemistry` or `English`.
3. The frontend loads topic metadata from `GET /topics`.
4. It fetches the selected topic configuration from `GET /simulation/{topic_id}`.
5. User input is sent to the backend:
   - Chemistry uses `POST /chemistry/reaction-rate`
   - English uses `POST /english/analyze`
6. The backend validates input, computes the result, caches it for 60 seconds, and returns a `cache_hit` flag.
7. The frontend renders either a line chart or highlighted sentence output.

## Seeded Lessons

| Subject | Topic | Input | Output |
| --- | --- | --- | --- |
| Chemistry | Reaction Rate Dynamics | Concentration and temperature sliders | Reaction rate, rate constant, and 25 chart points |
| English | Sentence Structure Explorer | Free-text sentence input | Subject, verb, object, and rich-text highlighting |

## Tech Stack

- Frontend: Flutter Web, `http`, `fl_chart`
- Backend: FastAPI, SQLAlchemy, Pydantic
- Database: SQLite for local development fallback, PostgreSQL for production-style setup
- Cache: Redis when `REDIS_URL` is configured, otherwise an in-memory cache
- Tests: `pytest` for backend, Flutter widget tests for frontend

## Repository Structure

```text
.
|-- backend/
|   |-- main.py
|   |-- database.py
|   |-- models.py
|   |-- redis_client.py
|   |-- requirements.txt
|   |-- routes/
|   |   |-- chemistry.py
|   |   |-- english.py
|   |   `-- topics.py
|   |-- schemas/
|   |   `-- pydantic_models.py
|   |-- services/
|   |   |-- chemistry_service.py
|   |   `-- english_service.py
|   `-- tests/
|       `-- test_api.py
|-- frontend/
|   |-- lib/
|   |   |-- main.dart
|   |   |-- screens/
|   |   |   |-- home_screen.dart
|   |   |   `-- subject_screen.dart
|   |   |-- services/
|   |   |   `-- api_service.dart
|   |   `-- widgets/
|   |       |-- input_panel.dart
|   |       `-- visualization_panel.dart
|   |-- test/
|   |   `-- widget_test.dart
|   `-- web/
|-- docker-compose.yml
`-- README.md
```

## Backend Behavior

### Startup And Data Seeding

- FastAPI calls `init_db()` during app startup.
- SQLAlchemy creates the tables automatically.
- If the database is empty, the backend seeds two topics and their simulation configs.

### Chemistry Flow

- Accepts `topic_id`, `concentration`, and `temperature`.
- Validates the input against the simulation config stored in the database.
- Uses a first-order decay model with an Arrhenius-inspired rate constant.
- Returns:
  - `rate`
  - `rate_constant`
  - `graph_points` from `t = 0.0` to `t = 12.0` in `0.5` increments
  - `formula`
  - `cache_hit`

Example request:

```json
{
  "topic_id": 1,
  "concentration": 2.5,
  "temperature": 320.0
}
```

### English Flow

- Accepts `topic_id` and a sentence.
- Normalizes whitespace and rejects empty input.
- Uses deterministic heuristics to find the verb phrase and split subject and object spans.
- Returns:
  - `subject`
  - `verb`
  - `object`
  - `segments` for frontend highlighting
  - `visualization`
  - `cache_hit`

Example request:

```json
{
  "topic_id": 2,
  "sentence": "The student writes a clear summary."
}
```

### Caching

- TTL is 60 seconds.
- If `REDIS_URL` is set and Redis is reachable, the backend uses Redis.
- If Redis is not configured or is unavailable, the backend falls back to an in-memory cache automatically.

## API Endpoints

| Method | Path | Purpose |
| --- | --- | --- |
| `GET` | `/health` | Basic health check |
| `GET` | `/topics` | Returns all seeded topics |
| `GET` | `/simulation/{topic_id}` | Returns a topic and its simulation config |
| `POST` | `/chemistry/reaction-rate` | Calculates chemistry results |
| `POST` | `/english/analyze` | Analyzes sentence structure |

When the backend is running, FastAPI also exposes interactive docs at `http://127.0.0.1:8000/docs`.

## Local Development Setup

### Prerequisites

- Python 3.12 or another recent Python 3 version compatible with the backend dependencies
- Flutter 3.41.x / Dart 3.11.x or another recent stable Flutter SDK

### 1. Start The Backend

From `backend/`:

```powershell
python -m venv .venv
.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
uvicorn main:app --reload
```

Default backend behavior for local development:

- If `APP_MODE` is not `production` and `DATABASE_URL` is unset, SQLAlchemy uses `sqlite:///./nexlearn.db`.
- That creates the local SQLite file `nexlearn.db` in the `backend/` directory.
- If `REDIS_URL` is unset, the backend uses the in-memory cache.
- `CORS_ALLOWED_ORIGINS` defaults to `*`.

### 2. Start The Frontend

From `frontend/`:

```powershell
flutter pub get
flutter run -d chrome
```

By default, the Flutter app looks for the API on the current host at port `8000`.
If your backend runs on a different address, pass `--dart-define=API_BASE_URL=http://127.0.0.1:8000` or your custom backend URL.

## Optional PostgreSQL And Redis With Docker

The repository includes `docker-compose.yml` for local PostgreSQL and Redis:

```powershell
docker compose up -d
```

Services started by Compose:

- PostgreSQL on `localhost:5432`
- Redis on `localhost:6379`

That matches the backend's production-style local connection settings:

- `DATABASE_URL=postgresql+psycopg://nexlearn:nexlearn@localhost:5432/nexlearn`
- `REDIS_URL=redis://localhost:6379/0`

## Environment Variables

| Variable | Default | Purpose |
| --- | --- | --- |
| `APP_MODE` | `development` | Switches between local fallback behavior and production-oriented defaults |
| `DATABASE_URL` | `sqlite:///./nexlearn.db` in development, local PostgreSQL URL in production if unset | SQLAlchemy connection string |
| `REDIS_URL` | unset | Enables Redis caching when provided |
| `CORS_ALLOWED_ORIGINS` | `*` | Comma-separated list of allowed origins |

Example PowerShell configuration for PostgreSQL plus Redis:

```powershell
$env:APP_MODE = "production"
$env:DATABASE_URL = "postgresql+psycopg://nexlearn:nexlearn@localhost:5432/nexlearn"
$env:REDIS_URL = "redis://localhost:6379/0"
$env:CORS_ALLOWED_ORIGINS = "http://127.0.0.1:3000,http://localhost:3000"
uvicorn main:app --reload
```

## Testing

### Backend

From `backend/`:

```powershell
python -m pytest tests -q
```

### Frontend

From `frontend/`:

```powershell
flutter test
flutter analyze
flutter build web
```
## Prompt Evolution
Initial start with ChatGPT for task understanding 
https://chatgpt.com/share/69ba6b59-4e4c-8013-a06f-eb9c50e156f8

Later, the prompts continue in the codex CLI

## Video Demo
video link: https://youtu.be/yy2A6TCSdxA


## Current Scope

- The app currently ships with one seeded chemistry lesson and one seeded English lesson.
- The English parser is heuristic-based and intentionally lightweight. It is not a full NLP pipeline.
- The frontend is topic-driven, so more lessons can be added by extending the seeded data and configs.
