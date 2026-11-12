import json
import logging

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


def health(event, context):
    request_id = event.get("requestContext", {}).get("requestId")
    logger.info("Health check api_request_id=%s", request_id)
    return {
        "statusCode": 200,
        "headers": {"content-type": "application/json", "cache-control": "no-store"},
        "body": json.dumps({"status": "ok", "service": "cloudpulse-edge"}),
    }
