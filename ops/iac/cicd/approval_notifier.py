import json
import boto3
import os
from datetime import datetime

def lambda_handler(event, context):
    """
    Lambda function to send notifications when pipeline reaches approval gates
    """
    
    # Initialize AWS clients
    sns = boto3.client('sns')
    codepipeline = boto3.client('codepipeline')
    
    # Get pipeline and execution details
    pipeline_name = event['detail']['pipeline']
    execution_id = event['detail']['execution-id']
    state = event['detail']['state']
    
    # Get pipeline execution details
    try:
        execution = codepipeline.get_pipeline_execution(
            pipelineName=pipeline_name,
            pipelineExecutionId=execution_id
        )
        
        pipeline_state = codepipeline.get_pipeline_state(name=pipeline_name)
        
        # Find the current stage
        current_stage = None
        for stage in pipeline_state['stageStates']:
            if stage['latestExecution']['status'] == 'InProgress':
                current_stage = stage['stageName']
                break
        
        if current_stage and 'approval' in current_stage.lower():
            # Send notification for approval
            message = f"""
🚨 Pipeline Approval Required

Pipeline: {pipeline_name}
Execution ID: {execution_id}
Stage: {current_stage}
Status: {state}
Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC')}

Please review and approve the deployment in the AWS Console:
https://console.aws.amazon.com/codesuite/codepipeline/pipelines/{pipeline_name}/view

This is an automated notification from the E-commerce CI/CD pipeline.
            """
            
            # Send to SNS topic
            sns_topic_arn = os.environ.get('SNS_TOPIC_ARN')
            if sns_topic_arn:
                sns.publish(
                    TopicArn=sns_topic_arn,
                    Message=message,
                    Subject=f"Pipeline Approval Required: {pipeline_name}"
                )
                
            print(f"Approval notification sent for pipeline {pipeline_name}")
        
    except Exception as e:
        print(f"Error processing approval notification: {str(e)}")
        raise e
    
    return {
        'statusCode': 200,
        'body': json.dumps('Approval notification processed')
    }
