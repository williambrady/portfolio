# portfolio
Sample project

Given the following criteria, options should be outlined and constructed.

## Requirements ##

Initial data source is a table, easily saved as a CSV file.

```
Model, Color, Make, Year
Golf, Silver, Volkswagon, 2005
```

- Develop an API to return car details.
- A user should be able to provide an ID and the API should return the relevant details for that car.
- If an invalid ID is provided, a "not found" message should be returned.
- Only use AWS or Azure services
- Solution is deployable as code with limited manual steps
- Dataset can be stored on any AWS or Azure data storage service including databases
- Do not hard code inputs, outputs, or dataset

## Optional Solutions ##

There are many ways these goals can be achieved, so a few options will be offered. There are no stated requirements for additional security, logging, or expectations around cost so options will start off basic and migrate into recommended.

### Cheapest AWS Solution ###
The cheapest and quickest option would be to drop the data into an S3 bucket in CSV format and leverage S3 Select to query the content. The gap from API request to S3 can be filled with API Gateway connected to a Lambda function. Since the solution must be deployed as code, the initial version will be built through Terraform to allow transition to other services and cloud platforms as requirements change. Since AWS S3 Select uses Presto on the backend, the data will have to have row identifiers added before query time. This will be handled via python pre-parser executed during S3 bucket setup. Additionally, there is an API test script that is initiated by the last TF creation,

Actions:

'''
terraform apply

python3 test-api.py
'''

Terraform initiates local-exec to:
 - Add a carID column to the dataset to emulate an index.
 - Package the Lambda Function into a zip file.
 - Verify the API deployment has completed successfully.

Assets:

- Data Set: (dataset.csv) Initial CSV file with car data
- Python Loader: (build.py) Add row numbers to the CSV to emulate an index.
- S3 Bucket, dataset: To house data for the project
- S3 Bucket Policy, dataset: To allow access to bucket and contents
- S3 Bucket, dataset: file placement
- Lambda Function Script: broker requests from API Gateway to S3
- Lambda Function Policy: Allow API Gateway to call Lambda and Lambda to access S3
- API Gateway Policy: Allow API Gateway to call Lambda
- API Gateway: Publish Endpoint that connects HTTPS to Lambda

### Recommended AWS Solution ###
The *recommended* option would be the same as the cheapest option, with additional logging and controls.

Actions:

'''
terraform apply

python3 test-api.py
'''

Terraform initiates local-exec to:
 - Add a carID column to the dataset to emulate an index.
 - Package the Lambda Function into a zip file.
 - Verify the API deployment has completed successfully.

Assets:

- Data Set: (dataset.csv) Initial CSV file with car data
- Python Loader: (build.py) Add row numbers to the CSV to emulate an index.
- IAM Role
- CloudTrail
- CloudWatch
- S3 Bucket, Logging:
- S3 Bucket, Logging:
- S3 Bucket, Dataset: To house data for the project
- S3 Bucket Policy, dataset: To allow access to bucket and contents
- S3 Bucket, Dataset: file placement
- Lambda Function Script: broker requests from API Gateway to S3
- Lambda Function Policy: Allow API Gateway to call Lambda and Lambda to access S3
- API Gateway Policy: Allow API Gateway to call Lambda
- API Gateway: Publish Endpoint that connects HTTPS to Lambda


### Scalable AWS Solution ###

If there is an potential for data growth or requirements for faster access, the deployment can be scaled out to include AWS RDS.



### Cheapest Azure Solution ###

- Microsoft Azure Blob Storage to house the file, converted from CSV to JSON before deposit
- Microsoft API Gateway to front-end the requests and enforce authentication
- ETL of files as needed

### Scalable Azure Solution ###

- SQL Server
- Microsoft API Gateway to front-end the requests and enforce authentication
