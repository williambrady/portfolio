import boto3
import sys

if len(event) < 1:
  print("Invalid input.")
  quit()
else:
  carId = event

# Simulate the API Gateway request from the CLI to ensure access is in place.
S3_QUERY = "select * from s3object s where s.\"carId\"=\'{}\'".format(id)
S3_BUCKET = 'portfolio-918573727633-us-east-1-dataset'
s3 = boto3.client('s3')

r = s3.select_object_content(
  Bucket=S3_BUCKET,
  Key='indexed_dataset.csv',
  ExpressionType='SQL',
  Expression=S3_QUERY,
  InputSerialization={'CSV': {"FileHeaderInfo": "Use"}},
  OutputSerialization={'JSON': {}},
)

for event in r['Payload']:
  if 'Stats' in event:
    statsDetails = event['Stats']['Details']
    if statsDetails['BytesReturned'] == 0:
      print("Record not found.")
      quit()
  elif 'Records' in event:
    records = event['Records']['Payload'].decode('utf-8')
    print("{}".format(event))
  else:
    quit()
