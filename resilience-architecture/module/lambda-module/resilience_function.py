import os
import json
import boto3
from botocore.exceptions import ClientError

dynamodb = boto3.client("dynamodb")

TABLE_NAME = os.environ["COUNTER_TABLE_NAME"]
PK_VALUE = "lambda_invocation_counter"


def _get_http_method(event):
    rc = event.get("requestContext", {})
    http = rc.get("http")
    if isinstance(http, dict) and "method" in http:
        return http["method"]

    if "httpMethod" in event:
        return event["httpMethod"]

    return "GET"


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

def _get_current_count():
    try:
        resp = dynamodb.get_item(
            TableName=TABLE_NAME,
            Key={"pk": {"S": PK_VALUE}},
            ConsistentRead=True,
        )
    except ClientError as e:
        print("GetItem error:", e)
        return 0

    item = resp.get("Item")
    if not item or "lambda_invoke_count" not in item:
        return 0

    return int(item["lambda_invoke_count"]["N"])


# Atomic increment
def _increment_and_return_count():
    try:
        dynamodb.update_item(
            TableName=TABLE_NAME,
            Key={"pk": {"S": PK_VALUE}},
            UpdateExpression="ADD #c :inc",
            ExpressionAttributeNames={"#c": "lambda_invoke_count"},
            ExpressionAttributeValues={":inc": {"N": "1"}},
        )
    except ClientError as e:
        print("UpdateItem error:", e)
        raise

    return _get_current_count()


def lambda_handler(event, context):
    print("Incoming event:", json.dumps(event))

    method = _get_http_method(event).upper()

    if method == "OPTIONS":
        return _response(200, {"ok": True})

    try:
        if method == "POST":
            count = _increment_and_return_count()
        else: 
            count = _get_current_count()
    except Exception as e:
        print("Unhandled error:", e)
        return _response(500, {"error": "Internal server error"})

    return _response(200, {"count": count})
