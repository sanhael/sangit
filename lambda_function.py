import boto3
import datetime

def lambda_handler(event, context):
    print("✅ Lambda triggered!")
    

    s3 = boto3.client('s3')
    
    try:
        bucket = event['Records'][0]['s3']['bucket']['name']
        key = event['Records'][0]['s3']['object']['key']
        print(f"🪣 Bucket Name: {bucket}")
        print(f"📄 Key value: {key}")

        response = s3.get_object(Bucket=bucket, Key=key)
        content = response['Body'].read().decode('utf-8')

        modified_content = content + "\n Content inside the file from S3 Bucket" 

        now = datetime.datetime.now().strftime("%Y%m%d%H%M%S")
        output_key = f"output_files/processed_{now}.txt"

        s3.put_object(Bucket=bucket, Key=output_key, Body=modified_content.encode('utf-8'))
        print(f"✅ File saved as: {output_key}")

    except Exception as e:
        print(f"❌ Error: {e}")
