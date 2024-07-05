import os
import boto3
import json
import sys
import subprocess

# pip install custom package to /tmp/ and add to path
subprocess.call('pip install requests -t /tmp/ --no-cache-dir'.split(), stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
sys.path.insert(1, '/tmp/')

import requests

def lambda_handler(event, context):
    secret_name = os.getenv("SECRET_NAME")
    region_name = os.getenv("AWS_REGION")

    # Create a Secrets Manager client
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=region_name
    )

    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_name
        )
    except Exception as e:
        print(f"Error retrieving secret: {e}")
        raise e

    # Decode the secret
    secret = get_secret_value_response['SecretString']
    secret_dict = json.loads(secret)
    discord_webhook_url = secret_dict['PIPELINE_ALERT_CHANNEL']

    # Process the SNS message
    for record in event['Records']:
        sns_message = record['Sns']['Message']
        send_message_to_discord(discord_webhook_url, sns_message)

def send_message_to_discord(webhook_url, message):
    try:
        formatted_message = json.loads(message)
        pretty_message = json.dumps(formatted_message, indent=4)
        state = formatted_message.get('detail', {}).get('state', 'UNKNOWN')
        pipeline_name = formatted_message.get('detail', {}).get('pipeline', 'UnknownPipeline')
        title = f"CodePipeline - {pipeline_name} - Execution State - {state}"

        data = {
            "embeds": [
                {
                    "title": title,
                    "description": "```json\n" + pretty_message + "\n```"
                }
            ]
        }
        response = requests.post(webhook_url, json=data)
        if response.status_code != 204:
            raise Exception(f"Failed to send message to Discord, status code: {response.status_code}, response: {response.text}")
    except json.JSONDecodeError:
        # If the message is not in JSON format, send it as is
        title = title if title else "CodePipeline Execution State Change"
        data = {
            "embeds": [
                {
                    "title": title,
                    "description": message
                }
            ]
        }
        response = requests.post(webhook_url, json=data)
        if response.status_code != 204:
            raise Exception(f"Failed to send message to Discord, status code: {response.status_code}, response: {response.text}")
