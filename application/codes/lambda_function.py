import os
import json
from datetime import datetime, timedelta, date
from typing import Any

import boto3
import requests
from aws_lambda_powertools import Logger
from aws_lambda_powertools.utilities.typing import LambdaContext
from boto3.dynamodb.types import TypeDeserializer


logger = Logger(service="cost-notification")

# Environment variables
COST_METRICS_VALUE = os.getenv("COST_METRICS_VALUE")
SETTINGS_TABLE = os.getenv("SETTINGS_TABLE")


# Main Lambda handler
def lambda_handler(event: dict[str, Any], context: LambdaContext) -> dict[str, Any]:
    """Main handler for Lambda function that fetches AWS cost information and sends it via LINE.

    Args:
        event: Lambda function event data
        context: Lambda execution context

    Returns:
        Dictionary containing response information
    """
    try:
        # Step 1: Get billing information from AWS Cost Explorer
        billing_info = fetch_aws_billing_info()
        if not billing_info:
            logger.error("Failed to get billing information")
            return {"statusCode": 500, "body": "Failed to get billing information"}

        logger.info(f"Total billing: {billing_info}")

        # Step 2: Format the notification message
        notification_message = format_billing_message(billing_info)
        if not notification_message:
            logger.error("Failed to format message")
            return {"statusCode": 500, "body": "Failed to format message"}

        logger.info(f"Message: {notification_message}")

        # Step 3: Get LINE notification tokens
        line_tokens = fetch_line_tokens()
        if not line_tokens:
            logger.error("Failed to get LINE tokens")
            return {"statusCode": 500, "body": "Failed to get LINE tokens"}

        # Step 4: Send notification to LINE
        response = send_line_notification(notification_message, line_tokens)
        if not response:
            logger.error("Failed to post to LINE")
            return {"statusCode": 500, "body": "Failed to post to LINE"}

        logger.info(f"Response: {response}")
        return {"statusCode": 200, "body": "Successfully sent cost notification"}

    except Exception as e:
        logger.exception("Unexpected error in lambda_handler")
        return {"statusCode": 500, "body": f"Error: {str(e)}"}


# --- AWS Cost Explorer Functions ---

def fetch_aws_billing_info() -> dict[str, str] | None:
    """Retrieve billing information from AWS Cost Explorer.

    Returns:
        Dictionary containing billing information (start date, end date, amount), None if failed
    """
    try:
        client = boto3.client('ce', region_name='us-east-1')
        start_date, end_date = calculate_billing_date_range()

        if not start_date or not end_date:
            logger.error("Failed to determine date range")
            return None

        response = client.get_cost_and_usage(
            TimePeriod={
                'Start': start_date,
                'End': end_date
            },
            Granularity='MONTHLY',
            Metrics=[COST_METRICS_VALUE]
        )

        extracted_res = response.get('ResultsByTime')[0]
        return {
            'start': extracted_res['TimePeriod']['Start'],
            'end': extracted_res['TimePeriod']['End'],
            'billing': extracted_res['Total'][COST_METRICS_VALUE]['Amount'],
        }
    except Exception as e:
        logger.exception(f"Error in fetch_aws_billing_info: {e}")
        return None


def calculate_billing_date_range() -> tuple[str | None, str | None]:
    """Determine date range for cost calculation.

    Returns:
        Tuple of (start_date, end_date), (None, None) if failed
    """
    try:
        start_date = get_first_day_of_month()
        end_date = get_today_date()

        if start_date == end_date:
            # If it's the first day of the month, get previous month's data
            end_of_month = datetime.strptime(start_date, '%Y-%m-%d') + timedelta(days=-1)
            begin_of_month = end_of_month.replace(day=1)
            return begin_of_month.date().isoformat(), end_date

        return start_date, end_date
    except Exception as e:
        logger.exception(f"Error in calculate_billing_date_range: {e}")
        return None, None


# --- Message Formatting Functions ---

def format_billing_message(billing_info: dict[str, str]) -> str | None:
    """Generate notification message from billing information.

    Args:
        billing_info: Dictionary containing billing information

    Returns:
        Formatted message string, None if failed
    """
    try:
        start = datetime.strptime(billing_info['start'], '%Y-%m-%d').strftime('%m/%d')
        end_today = datetime.strptime(billing_info['end'], '%Y-%m-%d')
        end_yesterday = (end_today - timedelta(days=1)).strftime('%m/%d')

        total = round(float(billing_info['billing']), 3)

        return f'{start}～{end_yesterday}の請求額は、{total:.3f} USDです。'
    except Exception as e:
        logger.exception(f"Error in format_billing_message: {e}")
        return None


# --- LINE Notification Functions ---

def fetch_line_tokens() -> dict[str, str] | None:
    """Get LINE notification tokens from DynamoDB.

    Returns:
        Dictionary containing LINE Channel ID and Access Token, None if failed
    """
    try:
        key_list = ['line_channel_id', 'line_access_token']
        token_list = []
        deserializer = TypeDeserializer()
        dynamodb = boto3.client('dynamodb')

        for key_name in key_list:
            options = {
                'TableName': SETTINGS_TABLE,
                'Key': {
                    'type': {'S': key_name},
                }
            }

            raw_response = dynamodb.get_item(**options)
            if 'Item' not in raw_response:
                logger.error(f"Key {key_name} not found in DynamoDB")
                return None

            converted_response = {
                k: deserializer.deserialize(v)
                for k, v in raw_response['Item'].items()
            }
            token_list.append(converted_response.get('value'))

        return {
            'channel_id': token_list[0],
            'access_token': token_list[1]
        }
    except Exception as e:
        logger.exception(f"Error in fetch_line_tokens: {e}")
        return None


def send_line_notification(message: str, token_dict: dict[str, str]) -> requests.Response | None:
    """Send message using LINE Messaging API.

    Args:
        message: Message to send
        token_dict: Dictionary containing LINE Channel ID and Access Token

    Returns:
        API response, None if failed
    """
    try:
        url = "https://api.line.me/v2/bot/message/push"
        headers = {
            "Authorization": f"Bearer {token_dict['access_token']}",
            "Content-Type": "application/json"
        }
        data = {
            "to": token_dict['channel_id'],
            "messages": [
                {
                    "type": "text",
                    "text": message
                }
            ]
        }

        response = requests.post(
            url,
            headers=headers,
            data=json.dumps(data)
        )
        response_json = response.json()
        logger.info(f"LINE API response: {response_json}")

        if response.status_code != 200:
            logger.error(f"LINE API error: {response.status_code} - {response_json}")
            return None

        return response
    except Exception as e:
        logger.exception(f"Error in send_line_notification: {e}")
        return None


# --- Date Utility Functions ---

def get_first_day_of_month() -> str:
    """Get the first day of current month in ISO format.

    Returns:
        Date string in YYYY-MM-DD format
    """
    return date.today().replace(day=1).isoformat()


def get_today_date() -> str:
    """Get today's date in ISO format.

    Returns:
        Date string in YYYY-MM-DD format
    """
    return date.today().isoformat()
