import boto3
import sys

# Simpulate the API Gateway request from the CLI to ensure access is in place.
S3_QUERY = "select * from s3object s where s.\"Id\"=\'{}\'".format(sys.argv[1])

print ("Query is",S3_QUERY)

S3_BUCKET = 'portfolio-918573727633-us-east-1-dataset'
s3 = boto3.client('s3')

r = s3.select_object_content(
    Bucket=S3_BUCKET,
    Key='dataset-numbered.csv',
    ExpressionType='SQL',
    Expression=S3_QUERY,
    InputSerialization={'CSV': {"FileHeaderInfo": "Use"}},
    OutputSerialization={'JSON': {}},
)

for event in r['Payload']:
    if 'Records' in event:
        records = event['Records']['Payload'].decode('utf-8')
        print(records)
    elif
        print("Record not found")
