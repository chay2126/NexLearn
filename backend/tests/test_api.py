import os

os.environ["APP_MODE"] = "test"
os.environ["DATABASE_URL"] = "sqlite:///./test_nexlearn.db"
os.environ.pop("REDIS_URL", None)

from fastapi.testclient import TestClient

from main import app


def test_healthcheck() -> None:
    with TestClient(app) as client:
        response = client.get("/health")
        assert response.status_code == 200
        assert response.json() == {"status": "ok"}


def test_topics_and_simulation() -> None:
    with TestClient(app) as client:
        topics_response = client.get("/topics")
        assert topics_response.status_code == 200
        topics = topics_response.json()
        assert len(topics) == 2
        assert {topic["type"] for topic in topics} == {"chemistry", "english"}

        chemistry_topic = next(topic for topic in topics if topic["type"] == "chemistry")
        simulation_response = client.get(f"/simulation/{chemistry_topic['id']}")
        assert simulation_response.status_code == 200
        simulation = simulation_response.json()
        assert simulation["config"]["visualization"] == "line_chart"
        assert len(simulation["config"]["inputs"]) == 2


def test_chemistry_reaction_rate_and_cache() -> None:
    payload = {
        "topic_id": 1,
        "concentration": 2.5,
        "temperature": 320.0,
    }
    with TestClient(app) as client:
        first_response = client.post("/chemistry/reaction-rate", json=payload)
        assert first_response.status_code == 200
        first_result = first_response.json()
        assert first_result["cache_hit"] is False
        assert len(first_result["graph_points"]) == 25
        assert first_result["rate"] > 0

        second_response = client.post("/chemistry/reaction-rate", json=payload)
        assert second_response.status_code == 200
        assert second_response.json()["cache_hit"] is True


def test_english_analysis_and_cache() -> None:
    payload = {
        "topic_id": 2,
        "sentence": "The student writes a clear summary.",
    }
    with TestClient(app) as client:
        first_response = client.post("/english/analyze", json=payload)
        assert first_response.status_code == 200
        first_result = first_response.json()
        assert first_result["subject"] == "The student"
        assert first_result["verb"] == "writes"
        assert first_result["object"] == "a clear summary"
        assert first_result["cache_hit"] is False

        second_response = client.post("/english/analyze", json=payload)
        assert second_response.status_code == 200
        assert second_response.json()["cache_hit"] is True
