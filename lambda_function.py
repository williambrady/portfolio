import boto3
import json

def lambda_handler(event, context):
  # Capture the incoming string as carId
  carId = event['queryStringParameters']['carId']
  # Build the SQL Query
  S3_QUERY = "select * from s3object s where s.\"carId\"=\'" + carId + "'"
      
  # Retrieve the S3 bucket name from SSM Parameter Store
  ssm = boto3.client('ssm')
  ssm_parameter = ssm.get_parameter(Name="/portfolio/s3_bucket_name", WithDecryption=True)
  print("Retrieved S3 Bucket Name: {}".format(ssm_parameter['Parameter']['Value']))
  S3_BUCKET = ssm_parameter['Parameter']['Value']
  
  # Make the call to S3 Select as CSV and ask for JSON returned content.
  s3 = boto3.client('s3')
  r = s3.select_object_content(
    Bucket=S3_BUCKET,
    Key='indexed_dataset.csv',
    ExpressionType='SQL',
    Expression=S3_QUERY,
    InputSerialization={'CSV': {"FileHeaderInfo": "Use"}},
    OutputSerialization={'JSON': {}},
  )

  # Construct the Response Body
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

  # Construct the HTTP Response
  responseObject = {}
  responseObject['statusCode'] = 200
  responseObject['headers'] = {}
  responseObject['headers']['Content-Type'] = 'application/json'
  responseObject['body'] = json.dumps(queryResponse)

  # Return the response object
  return responseObject
