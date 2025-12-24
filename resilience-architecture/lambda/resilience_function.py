import os
import json
import time
import boto3
from botocore.exceptions import ClientError

dynamodb = boto3.client("dynamodb")

TABLE_NAME = os.environ["COUNTER_TABLE_NAME"]
PK_VALUE = "lambda_invocation_counter"


def _now_epoch() -> int:
    return int(time.time())


def _get_http_method(event) -> str:
    rc = event.get("requestContext", {})
    http = rc.get("http")
    if isinstance(http, dict) and "method" in http:
        return http["method"]
    if "httpMethod" in event:
        return event["httpMethod"]
    return "GET"


def _get_path(event) -> str:
    if "rawPath" in event:
        return event["rawPath"] or "/"
    if "path" in event:
        return event["path"] or "/"

    rc = event.get("requestContext", {})
    http = rc.get("http")
    if isinstance(http, dict) and "path" in http:
        return http["path"] or "/"

    return "/"


def _response(status, body_dict):
    return {
        "statusCode": status,
        "headers": {
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Headers": "Content-Type",
            "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
        },
        "body": json.dumps(body_dict),
    }


def _get_item():
    try:
        resp = dynamodb.get_item(
            TableName=TABLE_NAME,
            Key={"partition_key": {"string": PK_VALUE}},
            ConsistentRead=True,
        )
        return resp.get("Item")
    except ClientError as e:
        print("DynamoDB get_item error:", e)
        raise


def _get_current_metrics():
    item = _get_item() or {}

    count = int(item.get("lambda_invoke_count", {}).get("N", "0"))
    last_ts = int(item.get("last_ts", {}).get("N", "0"))
    tick_rate_per_min = float(item.get("tick_rate_per_min", {}).get("N", "0"))

    return {
        "count": count,
        "last_ts": last_ts,
        "tick_rate_per_min": tick_rate_per_min,
        "ts": _now_epoch(),
    }


def _increment_by(n: int):
    """
    Atomically increments counter by n and updates tick rate.
    Tick rate model (simple): events per minute since last increment.
    """
    now = _now_epoch()

    item = _get_item() or {}
    prev_ts = int(item.get("last_ts", {}).get("N", "0"))

    if prev_ts > 0 and now > prev_ts:
        delta = now - prev_ts
        tick_rate_per_min = (n / delta) * 60.0
    else:
        tick_rate_per_min = 0.0

    try:
        resp = dynamodb.update_item(
            TableName=TABLE_NAME,
            Key={"partition_key": {"string": PK_VALUE}},
            UpdateExpression="ADD lambda_invoke_count :inc SET last_ts = :ts, tick_rate_per_min = :rate",
            ExpressionAttributeValues={
                ":inc": {"N": str(n)},
                ":ts": {"N": str(now)},
                ":rate": {"N": str(tick_rate_per_min)},
            },
            ReturnValues="UPDATED_NEW",
        )
    except ClientError as e:
        print("DynamoDB update_item error:", e)
        raise

    new_count = int(resp["Attributes"]["lambda_invoke_count"]["N"])
    return {
        "count": new_count,
        "last_ts": now,
        "tick_rate_per_min": tick_rate_per_min,
        "ts": now,
    }


def lambda_handler(event, context):
    if isinstance(event, dict) and "Records" in event:
        n = len(event["Records"])
        metrics = _increment_by(n)
        return {"ok": True, "processed": n, **metrics}

    method = _get_http_method(event).upper()
    path = _get_path(event)

    if method == "OPTIONS":
        return _response(200, {"ok": True})

    if method == "GET" and path.endswith("/metrics"):
        return _response(200, _get_current_metrics())

    try:
        if method == "POST":
            metrics = _increment_by(1)
            return _response(200, metrics)

        metrics = _get_current_metrics()
        return _response(200, metrics)

    except Exception as e:
        print("Unhandled error:", e)
        return _response(500, {"error": "Internal server error"})
