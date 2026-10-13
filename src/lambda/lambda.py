import json
import re
from collections import Counter

# words ignored when picking the most frequent words
STOP_WORDS = {
    "the", "a", "an", "and", "or", "but", "of", "to", "in", "on", "at", "for",
    "with", "is", "are", "was", "were", "be", "it", "this", "that", "as", "by",
}

# average adult reading speed (words per minute)
READING_WPM = 200


def analyse(text):
    words = re.findall(r"[A-Za-z0-9']+", text.lower())
    sentences = [s for s in re.split(r"[.!?]+", text) if s.strip()]
    top = Counter(w for w in words if w not in STOP_WORDS).most_common(5)

    return {
        "characters": len(text),
        "words": len(words),
        "sentences": len(sentences),
        "topWords": [{"word": w, "count": c} for w, c in top],
        "readingTimeSeconds": round(len(words) / READING_WPM * 60),
    }


def response(status, body):
    # API Gateway proxy integration expects this shape
    return {
        "statusCode": status,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body),
    }


def handler(event, context):
    # body arrives as a string, e.g. {"text": "some text"}
    try:
        payload = json.loads(event.get("body") or "{}")
    except json.JSONDecodeError:
        return response(400, {"error": "Body must be valid JSON"})

    text = payload.get("text") if isinstance(payload, dict) else None
    if not isinstance(text, str) or not text.strip():
        return response(400, {"error": "Send JSON like {\"text\": \"your text\"}"})

    return response(200, analyse(text))
