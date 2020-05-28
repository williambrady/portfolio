# portfolio
Sample project

Given the following criteria, options need to be outlined and constructed.

Initial data source is a table, easily saved as a CSV file.

```
Model, Color, Make, Year
Golf, Silver, Volkswagon, 2005
```

## Requirements

- Develop an API to return car details. A user should be able to provide an ID and the API should return the relevant details for that car. If an invalid ID is provided, a "not found" message should be returned.
- Only use AWS or Azure services
- Solution is deployable as code with limited manual steps
- Dataset can be stored on any AWS or Azure data storage service including databases
- Do not hard code inputs, outputs, or dataset

## Optional Solutions ##

### Cheapest AWS Solution ###
The cheapest and quickest option would be to drop the data into an S3 bucket in CSV format and leverage S3 Select to query the content. The gap from API request to S3 can be filled with API Gateway connected to a Lambda function. Since the solution must be deployed as code, the initial version will be built through Terraform to allow transition to other services and cloud platforms as requirements change.

Assets:

- (aws_s3_bucket.dataset) S3 bucket to house the data set.
- (aws_s3_bucket_policy.dataset) S3 bucket policy enforcing security controls such as disabling public access and enabling access logging.
- (aws_lambda_function.dataset) Lambda function written in Python to accept HTTP request from API Gateway, query S3 Select, format the response, and return content.
- (aws_apigateway.dataset) API Gateway HTTP service to accept GET requests for arbitrary carId value and return details.


### Scalable AWS Solution ###

If there is an potential for data growth or requirements for faster access, the deployment can be scaled out to include AWS RDS.

Assets:

- (aws_s3_bucket.dataset) S3 bucket to house the data set.
- (aws_s3_bucket_policy.dataset) S3 bucket policy enforcing security controls such as disabling public access and enabling access logging.
- (aws_db_instance.dataset) RDS MySQL Instance to serve the indexed dataset. This allows expansion into Multi-AZ scenarios for scaling.
- (aws_lambda_function.dataset) Lambda function written in Python to accept HTTP request from API Gateway, query RDS, format the response, and return content.
- (aws_apigateway.dataset) API Gateway HTTP service to accept GET requests for arbitrary carId value and return details.

### Secure AWS Solution ###

Logging should be implemented to capture actions related to the project. visibility into actions, access, and processes increase troubleshooting ability and security response capabilities.

Assets:

- (aws_s3_bucket.logging) S3 bucket to store all event logs related to the project
- (aws.cloudtrail.project) Event bus for AWS actions related to the project
- (aws_cloudwatch_log_group.project) Capture / process events from project
- (aws_s3_bucket.dataset) S3 bucket to house the data set. Access Logging set to (aws_s3_bucket.logging)
- (aws_s3_bucket_policy.dataset) S3 bucket policy enforcing security controls such as disabling public access and enabling access logging.
- (aws_lambda_function.dataset) Lambda function written in Python to accept HTTP request from API Gateway, query S3 Select, format the response, and return content.
- (aws_cognito.dataset) or (aws_iam_user.dataset) Authentication mechanism to protect the API endpoint
- (aws_apigateway.dataset) API Gateway HTTP service to accept GET requests for arbitrary carId value and return details.

### Cheapest Azure Solution ###

- (azure_storage.dataset) Microsoft Azure Blob Storage to house the file, converted from CSV to JSON before deposit
- (azure_apigateway.dataset) Microsoft API Gateway to front-end the requests and enforce authentication
- (azure_functions.dataset) ETL of files as needed

### Scalable Azure Solution ###

 - (azure_sqlserver.dataset) SQL Server
 - (azure_apigateway.dataset) Microsoft API Gateway to front-end the requests and enforce authentication

### Secure Azure Solution ###
