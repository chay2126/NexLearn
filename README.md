# LearnViz

## Project Overview
LearnViz is a production-oriented full-stack learning platform that combines chemistry simulations with English sentence analysis. The application uses a strict layered architecture: Flutter Web for presentation, FastAPI for the API layer, a dedicated service layer for chemistry and English logic, and a data layer designed for PostgreSQL persistence plus Redis caching.

## Problem Statement
Learning platforms often separate explanations from interactivity. LearnViz addresses that gap by letting learners change inputs and immediately see the consequences:

- `Chemistry`: adjust concentration and temperature and watch a reaction-decay graph update.
- `English`: type a sentence and see the detected subject, verb, and object highlighted in real time.

## Solution Approach
The solution is built around two seeded topics:

- `Reaction Rate Dynamics`
- `Sentence Structure Explorer`

The backend exposes topic metadata plus two interactive endpoints. The frontend fetches the available topics, loads the topic-specific simulation configuration, dynamically renders the appropriate input controls, and updates the visualization panel as the backend returns new data.

## Architecture Explanation
### 1. Presentation Layer
Flutter Web renders the UI, collects user input, and displays line charts or text highlighting.

### 2. API Layer
FastAPI routes handle request validation, dependency injection, and HTTP responses.

### 3. Service Layer
`chemistry_service.py` contains reaction-rate and graph generation logic based on `C(t) = C0 * e^(-kt)`. `english_service.py` contains sentence parsing and structured highlighting logic.

### 4. Data Layer
PostgreSQL stores seeded `topics` and `simulations` records. Redis caches chemistry and English results for 60 seconds using the required key formats.

## Data Flow
1. User interacts with Flutter.
2. Flutter calls FastAPI.
3. FastAPI invokes the service layer.
4. The service checks Redis first.
5. On a cache miss, the service reads topic and simulation metadata from PostgreSQL.
6. The service computes the result.
7. The result is cached for 60 seconds.
8. FastAPI returns the response.
9. Flutter updates the visualization panel.

## Features
- Topic catalog and dynamic simulation loading
- Chemistry sliders driven by backend simulation config
- English text analysis with RichText highlighting
- Separated API, service, and data layers
- SQLAlchemy models for `topics` and `simulations`
- Redis-style TTL caching for chemistry and English results
- Responsive two-panel UI
- Seed data initialization at backend startup
- Backend API tests and Flutter validation steps

## Backend Structure
```text
backend/
  main.py
  database.py
  redis_client.py
  models.py
  routes/
    topics.py
    chemistry.py
    english.py
  services/
    chemistry_service.py
    english_service.py
  schemas/
    pydantic_models.py
```

## Frontend Structure
```text
frontend/
  lib/
    main.dart
    screens/
      home_screen.dart
    widgets/
      input_panel.dart
      visualization_panel.dart
    services/
      api_service.dart
```

## Setup Steps
### Backend
1. Create and activate a virtual environment inside `backend/`.
2. Install dependencies with `pip install -r requirements.txt`.
3. Configure production environment variables:
   `APP_MODE=production`
   `DATABASE_URL=postgresql+psycopg://learnviz:learnviz@localhost:5432/learnviz`
   `REDIS_URL=redis://localhost:6379/0`
4. Start the API from `backend/` with `uvicorn main:app --reload`.

### Frontend
1. From `frontend/`, run `flutter pub get`.
2. Launch the web app with `flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000`.

## Optional Local Infrastructure
If Docker is available on your machine, the included `docker-compose.yml` starts PostgreSQL and Redis with persistent volumes.

## Development Phases
### Phase 1
Backend scaffold, SQLAlchemy models, startup seeding, Redis abstraction, and API routes.

### Phase 2
Chemistry simulation implemented with formula-driven graph generation and result caching.

### Phase 3
English sentence analysis implemented with subject/verb/object extraction and caching.

### Phase 4
Flutter Web interface implemented with a responsive two-panel layout, topic-driven inputs, chart rendering, and text highlighting.

### Phase 5
Integration and validation through backend tests, Flutter analysis, Flutter tests, and a web build.

## Testing
### Backend
From `backend/`, run `pytest tests -q`.

### Frontend
From `frontend/`, run:

- `flutter analyze`
- `flutter test`
- `flutter build web`

## Production Notes
- The backend is configured for PostgreSQL and Redis through environment variables.
- In this workspace, the backend can fall back to SQLite and in-memory caching when PostgreSQL or Redis are not available locally. That keeps the app runnable for development and testing without changing the layered architecture.
- For strict production deployment, set `APP_MODE=production`, provide a PostgreSQL `DATABASE_URL`, and provide a Redis `REDIS_URL`.

## Prompt Evolution
### Initial Prompt
Build a production-quality full-stack web application named LearnViz with Flutter Web, FastAPI, PostgreSQL, Redis, chemistry simulations, English analysis, and a strict layered architecture.

### Refined Prompt
Structure the backend into API, service, and data layers; seed topic and simulation data; cache chemistry and English responses with a 60-second TTL; build a responsive two-panel Flutter interface that renders inputs dynamically from backend configuration; and provide setup, testing, and architecture documentation.

### Explanation Of Decisions
- Seeded topics make the project usable on first start without manual SQL setup.
- Chemistry logic uses a first-order decay model with an Arrhenius-inspired rate constant so temperature visibly changes the curve.
- English analysis uses deterministic heuristics instead of an external NLP service to keep the project self-contained.
- Local development fallbacks were added because the current environment does not include PostgreSQL, Redis, or Docker binaries, while the production path remains PostgreSQL plus Redis.
