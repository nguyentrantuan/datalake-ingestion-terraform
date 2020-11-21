provider "aws" {
  region     = var.region
}
terraform {
  backend "s3" {
    bucket = "xxx-terrafrom-bucket"
    key    = "datalake_ingestion/"
    region = "us-east-1"
  }
}




#######################################te###########################################
# DMS
##################################################################################

module "dms" {
  source = "./modules/DMS"
  region = var.region
  ### instance variables
  vpc_id = var.vpc_id
  allocated_storage = var.allocated_storage
  replication_instance_class = var.replication_instance_class
  replication_instance_id = var.replication_instance_id
  mssql_ingress_cidr_blocks = var.mssql_ingress_cidr_blocks
  mysql_ingress_cidr_blocks = var.mysql_ingress_cidr_blocks
  tags = var.dms_instance_tags

  ### S3 variables
  clean_bucket_name = var.clean_bucket_name
  pub_bucket_name = var.pub_bucket_name
  raw_bucket_name = var.raw_bucket_name
  force_destroy_s3 = var.force_destroy_s3

  ### Source variables
  endpoints_list = var.endpoints_list

  ### Glue Crawler variables

  schedule = var.crawler_schedule

  ### Rep tasks variables

  replication_task_settings = var.replication_task_settings
  target_s3_settings = var.target_s3_settings
  table_mapping_default = var.table_mapping_default
  list_glue_iam_roles = var.list_glue_iam_roles
  list_glue_trusted_service = var.list_glue_trusted_service


#  destination_bucket_name = var.destination_bucket_name
}

