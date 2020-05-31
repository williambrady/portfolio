import boto3
import json

def lambda_handler(event, context):
  # Parse the incoming string
  carId = event['queryStringParameters']['carId']
  S3_QUERY = "select * from s3object s where s.\"carId\"=\'" + carId + "'"
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

  # Construct the response body
  queryResponse = {}

  for event in r['Payload']:
    if 'Stats' in event:
      statsDetails = event['Stats']['Details']
      if statsDetails['BytesReturned'] == 0:
        queryResponse['Result'] = "Record not found."
        pass
    elif 'Records' in event:
      records = event['Records']['Payload'].decode('utf-8')
      queryResponse['Result'] = records
      print("{}".format(event))
    else:
      pass

  # Construct the HTTP response
  responseObject = {}
  responseObject['statusCode'] = 200
  responseObject['headers'] = {}
  responseObject['headers']['Content-Type'] = 'application/json'
  responseObject['body'] = json.dumps(queryResponse)

  # Return the response object
  return responseObject
