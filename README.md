# portfolio
Sample project

Given the following criteria, options will be outlined and constructed.

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
The cheapest and quickest option would be to drop the data into an S3 bucket in CSV format and leverage S3 Select to query the content. The gap from API request to S3 can be filled with API Gateway connected to a Lambda function. Since the solution must be deployed as code, the initial version will be built through Terraform to allow transition to other services and cloud platforms as requirements change. Since AWS S3 Select uses Presto on the backend, the data will have to have row identifiers added before query time. This will be handled via python pre-parser executed during S3 bucket setup.

If this code was loaded into a deployment pipeline, the content could be formatted outside terraform. Additionally, the post-deployment testing could be executed automatically.

*Pros:* Low complexity, low cost

*Cons:* Low resilience, built for slow response time, low visibility

Actions:

Before executing a build, update the terraform.tfvars and variables.tf files to reflect your AWS account and desired project name. Additionally, since there was a requirement to not hardcode inputs, the source file has been removed from the terraform.tfvars file and should be input as a variable at run-time. This is method is more inline with pipeline builds.

```
terraform apply -var 'infile=dataset.csv'
    <or>
terraform apply -auto-approve -var 'infile=dataset.csv'

python3 test-api.py
```

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

### Recommended AWS Solution (What is actually built) ###
The *recommended* option would be the same as the cheapest option, with additional logging and controls.

*Pros:* Low complexity, low cost, reasonable visibility for operations and security teams

*Cons:* Low resilience, built for slow response time

Actions:

```
terraform apply -var 'infile=dataset.csv'
    <or>
terraform apply -auto-approve -var 'infile=dataset.csv'

python3 test-api.py
```

Terraform initiates local-exec to:
 - Add a carID column to the dataset to emulate an index.
 - Package the Lambda Function into a zip file.
 - Verify the API deployment has completed successfully.

Assets:

- Data Set: (dataset.csv) Initial CSV file with car data
- Python Loader: (build.py) Add row numbers to the CSV to emulate an index.
- CloudTrail: Configured to record all S3 access and Lambda execution details.
- S3 Bucket, Logging: To house security and operational logging.
- S3 Bucket Policy, Logging: To allow log delivery access to bucket  while explicitly denying public access.
- S3 Bucket, Dataset: To house data for the project
- S3 Bucket Policy, dataset: To allow access to bucket and contents while explicitly denying public access.
- S3 Bucket, Dataset: file placement
- Lambda Function Script: broker requests from API Gateway to S3
- Lambda Function Policy: Allow API Gateway to call Lambda and Lambda to access S3
- API Gateway Policy: Allow API Gateway to call Lambda
- API Gateway: Publish Endpoint that connects HTTPS to Lambda


### Scalable AWS Solution ###

If there is an potential for data growth or requirements for faster access, the deployment can be scaled out to include AWS RDS. In this scenario, a method to load the initial data into RDS would be required. This could be handled via Lambda or EC2. Optionally, one could attempt to  write the initial data set into a MySQL backup format (Percona Xtrabackup) that can be consumed at deployment time for the load process, but a single execution Lambda would likely be a better use of time.

There are two challenges with this scenario:
 - Loading Data: a single-execution Lambda would be preferable to an EC2 instance from a cost and cleanliness perspective.
 - Secrets handling: The database requires a credential set to grant access. This credential needs to be accessible to the Lambda function making the call. This can be wrapped in AWS Secrets Manager or in SSM Parameter Store, with preference for Secrets Manager. SSM PS is cheaper, but has a lower SLA and may not scale as well.
 - Introduction of a network layer: The original solution communicated via AWS ARNs. RDS will open a TCP listener that will reside on a network somewhere. To protect this, a VPC should exist with the RDS instance bound to the private subnets. Additionally, the Lambda function will need refitting to bind to the same VPC (private subnets as well) to allow communication.

Other than these pieces, the original stack can be used with minimal updates.


### What I would do differently ###

If I were to continue evolving this project, I have a few things I would improve.

- Convert my code into modules. I wrote this project from scratch as I have always created for work, but I did not want to reuse code that was not 100% mine. My initial version is long-hand, but I would like to rewrite into modules for re-use.
- Create the TF code for RDS deployment. I would like to practice RDS deployment methods, so it would be handy to create the reference code in my personal repo for quick reference
- Create the Microsoft Azure equivalent of this stack in Terraform. Azure API Management, Azure Functions, and Azure Storage should be able to accomplish the same task.
- Consider and deploy authentication options. I have worked heavily with SSO / SAML integration, but have limited experience with implementing API authentication options.

I would also like to see other submissions to solve this problem. Seeing how other people approached the problem could be helpful and adopting any coding nuances that I like from their solutions could be beneficial. The more I see, the better I can be.

# Technical Development Notes

## Example of importing existing resources:

There are many reasons you may have to import an existing resource to your current state, but here's an example.

If `terraform apply` returns something  like the following:

```
╷
│ Error: creating IAM Role (portfolio-lambda_s3_read-role): EntityAlreadyExists: Role with name portfolio-lambda_s3_read-role already exists.
│       status code: 409, request id: 90b68894-c0f4-42bc-bbd0-f6e7326bb326
│
│   with aws_iam_role.lambda_s3_read,
│   on aws-lambda-s3select.tf line 4, in resource "aws_iam_role" "lambda_s3_read":
│    4: resource "aws_iam_role" "lambda_s3_read" {
│
╵
╷
│ Error: creating IAM Policy (portfolio-lambda_s3_read-policy): EntityAlreadyExists: A policy called portfolio-lambda_s3_read-policy already exists. Duplicate names are not allowed.
│       status code: 409, request id: f6442598-5b9f-40a9-b37d-d205753f5f0e
│
│   with aws_iam_policy.lambda_s3_read,
│   on aws-lambda-s3select.tf line 26, in resource "aws_iam_policy" "lambda_s3_read":
│   26: resource "aws_iam_policy" "lambda_s3_read" {
```

You can import the existing resources like so:

```
terraform import aws_iam_role.lambda_s3_read portfolio-lambda_s3_read-role
terraform import aws_iam_policy.lambda_s3_read arn:aws:iam::918573727633:policy/portfolio-lambda_s3_read-policy
```

## How do you replace a bad randomly generated value?

Every now and then the random_pet resource will generate a string that combines with other string requirements and exceeds naming restrictions. You can correct this by either destroying and trying again, or simply tell terraform to generate another random_pet: `terraform apply -replace="random_pet.george"`
