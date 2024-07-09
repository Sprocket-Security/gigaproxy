import json
import requests
import os
import base64

# Determine if the content should be treated as binary
# Note there's some extra shit you have to do in API Gateway to support binary output, and even then it can sometimes be a crapshoot
binary_content_types = [
    'image/', 'application/pdf', 'application/octet-stream'
]

# Format incoming requests to drop headers we don't want to send out
def drop_incoming_headers(event):
    if "Host" in event["headers"].keys():
        event["headers"].pop("Host")
    
    if "X-Amzn-Trace-Id" in event["headers"].keys():
        event["headers"].pop("X-Amzn-Trace-Id")
    
    if "X-Forwarded-For" in event["headers"].keys():
        event["headers"].pop("X-Forwarded-For")
    
    if "x-api-key" in event["headers"].keys():
        event["headers"].pop("x-api-key")


def lambda_handler(event, context):
    # print incoming event to log if x-debug-call header is sent
    if "x-debug-call" in event["headers"].keys():
        print(event)

    url = event["headers"].pop("forward-me-to")
    
    if not url:
        return {
            "statusCode": 400,
            "body": "Request did not contain necessary header."
        }
    
    # Extract request details
    method = event["httpMethod"]
    drop_incoming_headers(event)
    headers = event["headers"]
    body = event["body"]
    params = event["queryStringParameters"]
    
    # Forward the request to the destination server
    response = requests.request(method, url, headers=headers, data=body, params=params, verify=False)
    
    # Read the response content fully -- need to do this, especially if responses are chunked
    response_content = response.content
    
    # Determine the content type of the response
    content_type = response.headers.get('Content-Type', 'application/json')
    
    # Handle binary content or not, depending on Content-Type header
    if any(content_type.startswith(bct) for bct in binary_content_types):
        response_body = base64.b64encode(response_content).decode('utf-')
        is_base64 = True
    else:
        response_body = response_content.decode('utf-8')
        is_base64 = False
    
    # Return the response in the required format
    return {
        'statusCode': response.status_code,
        'headers': {
            'Content-Type': content_type
        },
        'isBase64Encoded': is_base64,
        'body': response_body
    }
