variable "region" {
  description = "AWS region"
}
##################################################################################
# Variables - REPLICATION INSTANCE VARIABLES
#################################################################################
variable "vpc_id" {
  description = "selected VPC of DMS"
  type = string
}
variable "replication_instance_id" {
  description = "Name of DMS instance"
}

variable "allocated_storage" {
	description = "Storage on DMS instance in GB"
	type = number
}
variable "replication_instance_class" {	
	description = "instance type"
	type = string
}

variable "tags" {	type = map}

# CIDR_Blocks for DMS instance

variable "mssql_ingress_cidr_blocks" {
  type = list(string)
}
variable "mysql_ingress_cidr_blocks" {
  type = list(string)
}

##################################################################################
# Variables - REPLICATION TASKS
#################################################################################

variable replication_task_settings {type = any}
variable table_mapping_default {type = any}


##################################################################################
# VARIABLES - S3 TARGET endpoints
#################################################################################
variable "raw_bucket_name" {
  description = "name of raw bucket"
  type = string
}

variable "clean_bucket_name" {
  description = "name of clean bucket"
  type = string
}
variable "pub_bucket_name" {
  description = "name of publish bucket"
  type = string
}
variable "force_destroy_s3" {
  description = "force destroy non-empty s3 bucket"
  type = bool
}
variable "target_s3_settings" {
  type = object({
    bucket_folder    = string
#    bucket_name      = string
    compression_type = string
	external_table_definition = string
	csv_row_delimiter  = string
	csv_delimiter = string
	extra_connection_attributes = string
	extra_s3_attributes_cli = string
  })
  default =  null
}
 
variable "source_elasticsearch_settings" {
  type = object({
    endpoint_uri    = string
    error_retry_duration       = number
    full_load_error_percentage   = number
	service_access_role_arn = string
  })
  default =  null
}

variable "source_kinesis_settings" {
  type = object({
    message_format    = string
    stream_arn       = string
	service_access_role_arn = string
  })
  default =  null
}

##################################################################################
# SOURCE VARIABLES
#################################################################################


variable "endpoints_list" {
  description = "Map from list of endpoints to create resources"
  type = any
}

variable "source_s3_settings" {
  type = object({
    bucket_folder    = string
    bucket_name      = string
    compression_type = string
	service_access_role_arn = string
	external_table_definition = string
	csv_row_delimiter  = string
	csv_delimiter = string

  })
  default =  null
}

##################################################################################
# GLUE CRAWLER VARIABLES
#################################################################################

variable "schedule" {
	description = "schedule to run crawler"
	type = string
}

variable "list_glue_iam_roles" {
  type = set(string)
  description = "list of roles for aws glue to be assumed"

}

variable "list_glue_trusted_service" {
  type = set(string)
  description = "list of trusted service can assume glue roles"
}
