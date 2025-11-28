import json
import os
import urllib.request
import urllib.error

GROQ_API_KEY = os.environ.get("testapi")
GROQ_API_URL = "https://api.groq.com/openai/v1/chat/completions"
MODEL_NAME = os.environ.get("MODEL_NAME", "llama-3.1-8b-instant")


def _response(status_code: int, body: dict) -> dict:
    """Helper to build API Gateway HTTP API v2 response."""
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",  
            "Access-Control-Allow-Headers": "Content-Type",
            "Access-Control-Allow-Methods": "OPTIONS,POST",
        },
        "body": json.dumps(body),
    }


def lambda_handler(event, context):
    http_method = (
        event.get("requestContext", {}).get("http", {}).get("method", "")
    )

    if http_method == "OPTIONS":
        return _response(200, {"message": "ok"})

    try:
        raw_body = event.get("body") or "{}"
        body = json.loads(raw_body)
        user_message = (body.get("message") or "").strip()

        if not user_message:
            return _response(400, {"error": "Missing 'message' in request body"})

        if not GROQ_API_KEY:
            return _response(500, {"error": "GROQ_API_KEY not configured"})

        payload = {
            "model": MODEL_NAME,
            "messages": [
                {
                    "role": "system",
                    "content": """
                        You are a simple weather assistant.

                        Primary behavior:
                        - Answer questions about weather, temperature, climate, seasons, storms, humidity, forecasts, etc.
                        - When users ask general chat questions, answer briefly and redirect back to weather topics.

                        Example behaviors:
                        User: "who are you?"
                        You: "I'm a weather assistant — ask me anything about weather!"

                        User: "hello"
                        You: "Hi! What city or location's weather would you like to know?"

                        User: "tell me a joke"
                        You: "Sure — but weather is my specialty! Why don't clouds ever date? They prefer long-distance relationships."
                        """
                },
                {
                    "role": "user",
                    "content": user_message,
                },
            ],
        }

        data_bytes = json.dumps(payload).encode("utf-8")

        req = urllib.request.Request(
            GROQ_API_URL,
            data=data_bytes,
            method="POST",
            headers={
                "Authorization": f"Bearer {GROQ_API_KEY}",
                "Content-Type": "application/json",
            },
        )

        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                resp_body = resp.read().decode("utf-8")
        except urllib.error.HTTPError as e:
            err_body = e.read().decode("utf-8")
            print("Groq HTTPError:", e.code, err_body)
            return _response(502, {"error": "Error from Groq API"})

        groq_data = json.loads(resp_body)

        reply = (
            groq_data.get("choices", [{}])[0]
            .get("message", {})
            .get("content", "No response from model.")
        )

        return _response(200, {"reply": reply})

    except Exception as e:
        print("Unhandled exception:", repr(e))
        return _response(500, {"error": "Internal server error"})

