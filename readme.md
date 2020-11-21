# Terraform to create: 
- DMS instance including necessary roles (vpc role, cloudwatch log role, glue role), DMS subnet group and security group 
- DMS Endpoints (Schema source and S3 target)
- DMS Replication tasks
- Glue Database for each database source
- Glue Crawler to capture data structure for S3 source, run daily

## Pre-requirements
 1 - The source database needs to have its replication settings turned on 
 - SQL https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Source.SQLServer.html
 - MySQL https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Source.MySQL.html
 - etc.
 2 - Networking between DMS and database servers should be setup before hand (like VPC, Subnet, etc.)
 3 - Should have IAM admin role to create Policy and role
 4 - Setup RAW S3 bucket and terraform Remote backend S3 bucket beforehand
 
 ## Usage
 - Modify terraform.tfvars to correct parametters: AWS Region, VPC, S3 buckets (raw bucket and remote state in main.tf)
 - Setup IAM policy to scope down access. The default provided list gives full-access to all necessary services (Glue, S3)
 - Setup source endpoint list:
    - each block is equivalent to 1 SQL or MySQL (or any database source of your choice, need to modify security group in DMS module though) database with target Glue database and designated S3 destination
    - also each database can have separate transformation rules: include, exclude certain tables, add/remove/rename column. More on this: https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Tasks.CustomizingTasks.TableMapping.SelectionTransformation.Selections.html
## Creating your infrastructure

1. `terraform init`
2. `terraform plan`
3. `terraform apply`

## Destroying your infrastructure
`terraform destroy`
