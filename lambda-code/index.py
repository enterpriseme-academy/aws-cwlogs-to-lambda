import json
import gzip
import base64


def lambda_handler(event, context):
    """
    Lambda function to process and print CloudWatch Logs.
    
    This function receives compressed log data from CloudWatch Logs,
    decompresses it, and prints the log events.
    """
    # Decode and decompress the log data
    compressed_payload = base64.b64decode(event['awslogs']['data'])
    uncompressed_payload = gzip.decompress(compressed_payload)
    log_data = json.loads(uncompressed_payload)
    
    # Print log metadata
    print(f"Log Group: {log_data['logGroup']}")
    print(f"Log Stream: {log_data['logStream']}")
    print(f"Message Type: {log_data['messageType']}")
    print(f"Owner: {log_data['owner']}")
    print(f"Subscription Filters: {log_data['subscriptionFilters']}")
    
    # Print individual log events
    print("\n=== Log Events ===")
    for log_event in log_data['logEvents']:
        print(f"Timestamp: {log_event['timestamp']}")
        print(f"Message: {log_event['message']}")
        print(f"ID: {log_event['id']}")
        print("-" * 50)
    
    return {
        'statusCode': 200,
        'body': json.dumps('Log processing completed successfully')
    }
