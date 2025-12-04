import json

def lambda_handler(event, context):
    """
    Placeholder AWS Lambda handler that returns a simple message.
    """
    print("Hello from the placeholder Lambda function!")
    return {
        'statusCode': 200,
        'body': json.dumps('Hello from Lambda!')
    }