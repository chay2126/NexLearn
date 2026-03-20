# NexLearn

> An interactive learning platform where students explore Chemistry and English through live visualizations and an AI-powered tutor.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat&logo=flutter&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=flat&logo=python&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=flat&logo=fastapi&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?style=flat&logo=postgresql&logoColor=white)
![Redis](https://img.shields.io/badge/Redis-DC382D?style=flat&logo=redis&logoColor=white)
![Google Gemini](https://img.shields.io/badge/Gemini_AI-8E75B2?style=flat&logo=google&logoColor=white)
![Render](https://img.shields.io/badge/Render-46E3B7?style=flat&logo=render&logoColor=black)
![GitHub Pages](https://img.shields.io/badge/GitHub_Pages-222222?style=flat&logo=github&logoColor=white)

---

## Live Demo

🔗 **Live Link:** NexLearn.chaitanya999.online

▶️ **Demo Video:** Watch on YouTube → https://youtu.be/yy2A6TCSdxA

---

## Screenshots

### Home Screen
![Home Screen](screenshots/home_screen.png.png)

### Chemistry — Reaction Rate Dynamics
![Chemistry Screen](screenshots/chemistry_screen.png.png)

### English — Sentence Structure Explorer
![English Screen](screenshots/english_screen.png.png)

### AI Tutor Chatbot
![Chatbot](screenshots/chatbot.png.png)

---

## What It Does

NexLearn gives students a **split-panel workspace** — theory and controls on the left, live visualization on the right. Every input change instantly updates the chart or analysis without a page reload.

### Chemistry — Reaction Rate Dynamics
Students adjust **concentration** and **temperature** sliders and watch a real-time concentration-decay curve redraw. The backend calculates the Arrhenius rate constant and returns 25 graph points using the formula:

```
C(t) = C₀ × e^(-kt)
```

### English — Sentence Structure Explorer
Students type any English sentence and instantly see it **color-coded** by grammatical role — subject in blue, verb in red, object in green — with a full breakdown below the highlighted sentence.

### AI Tutor
An embedded chatbot powered by **Google Gemini** sits at the bottom of each lesson. It's scoped to the current topic — if a student asks something unrelated, the tutor redirects them back to the subject.

---

## Tech Stack

| Layer | Technology | Purpose |
|---|---|---|
| Frontend | Flutter (Web) | Split-panel UI, live charts, chatbot widget |
| Backend | Python + FastAPI | REST API, subject logic, Gemini integration |
| Database | PostgreSQL | Lesson content, simulation config, saved results |
| Cache | Redis | Computed results cached for 5 minutes |
| Chemistry engine | Custom Arrhenius model | Rate constant calculation, decay curve generation |
| English engine | Regex-based parser | Tokenization, verb/subject/object detection |
| AI Chatbot | Google Gemini 2.5 Flash Lite | Topic-scoped tutoring |
| Frontend deploy | GitHub Pages | Static Flutter web build |
| Backend deploy | Render | FastAPI server hosting |

---

## Project Structure

```
NexLearn/
├── backend/
│   ├── main.py                      # FastAPI entry point
│   ├── database.py                  # SQLAlchemy + seed data
│   ├── models.py                    # Topic & Simulation tables
│   ├── redis_client.py              # Redis + in-memory cache fallback
│   ├── routes/
│   │   ├── topics.py                # GET /topics, GET /simulation/{id}
│   │   ├── chemistry.py             # POST /chemistry/reaction-rate
│   │   ├── english.py               # POST /english/analyze
│   │   └── chat.py                  # POST /chat/message
│   ├── services/
│   │   ├── chemistry_service.py     # Arrhenius calculation + graph points
│   │   ├── english_service.py       # Sentence parsing + segmentation
│   │   └── chat_service.py          # Gemini API integration
│   └── schemas/
│       └── pydantic_models.py       # Request/response models
│
└── frontend/
    └── lib/
        ├── main.dart                # App entry, theme
        ├── screens/
        │   ├── home_screen.dart     # Subject selector
        │   └── subject_screen.dart  # Split-panel workspace
        ├── widgets/
        │   ├── input_panel.dart     # Left panel: theory + controls
        │   ├── visualization_panel.dart  # Right panel: chart/highlight
        │   └── chat_widget.dart     # AI tutor chatbot
        └── services/
            └── api_service.dart     # HTTP client + data models
```

---

## API Endpoints

| Method | Endpoint | Description |
|---|---|---|
| GET | `/topics` | List all topics |
| GET | `/simulation/{topic_id}` | Get simulation config for a topic |
| POST | `/chemistry/reaction-rate` | Calculate reaction rate and decay curve |
| POST | `/english/analyze` | Parse sentence into subject/verb/object |
| POST | `/chat/message` | Send message to Gemini AI tutor |
| GET | `/health` | Health check (used to keep Render warm) |

---

## Caching Strategy

Results are cached in **Redis** (or in-memory as fallback) using a structured key:

```
chemistry:topic=1:concentration=1.00:temperature=300.00
english:the student writes a clear summary
chat:topic=1:msg=what is reaction rate?
```

- Chemistry and English results: **5-minute TTL**
- Chat (single-turn only): **5-minute TTL**
- Multi-turn chat conversations: **not cached** (history changes every message)

---

## Database Schema

```sql
-- Topic metadata and lesson content
CREATE TABLE topics (
  id          SERIAL PRIMARY KEY,
  title       VARCHAR(120),
  description TEXT,
  type        ENUM('chemistry', 'english'),
  formula     VARCHAR(255)
);

-- Simulation configuration per topic
CREATE TABLE simulations (
  id       SERIAL PRIMARY KEY,
  topic_id INT REFERENCES topics(id) ON DELETE CASCADE,
  config   JSONB   -- inputs, visualization type
);
```

---

## Running Locally

### Backend

```bash
cd backend
python -m venv .venv
.venv\Scripts\activate       # Windows
source .venv/bin/activate    # Mac/Linux

pip install -r requirements.txt
```

Create a `.env` file:

```env
GEMINI_API_KEY=your_gemini_key
DATABASE_URL=postgresql://user:pass@localhost:5432/nexlearn
REDIS_URL=redis://localhost:6379
```

Start the server:

```bash
uvicorn main:app --reload
```

API docs available at `http://127.0.0.1:8000/docs`

### Frontend

```bash
cd frontend
flutter pub get
flutter run -d chrome
```

---

## Key Design Decisions

**Why FastAPI?** Async-first, automatic Pydantic validation, and built-in `/docs` — perfect for a learning API that needs clear contracts between frontend and backend.

**Why Redis with in-memory fallback?** The app works without Redis configured — the `InMemoryCache` class handles caching locally. Redis is only needed in production for shared caching across multiple server instances.

**Why no spaCy?** The English parser uses a custom regex and vocabulary-based approach instead of spaCy to keep the deployment lightweight on Render's free tier. No large model downloads needed on cold start.

**Why Gemini 2.5 Flash Lite?** Highest free-tier request limits (1,000 req/day) among currently available Gemini models — sufficient for a student learning app without any billing setup.

---