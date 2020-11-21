##################################################################################
# IAM ROLES FOR DMS
##################################################################################

module "dms_vpc_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 2.0"

  trusted_role_actions=[  "sts:AssumeRole"
  ]
  trusted_role_services = ["dms.amazonaws.com",
  ]
  create_role = true

  role_name         = "dms-vpc-role"
  role_requires_mfa = false

  custom_role_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonDMSVPCManagementRole"]
}
module "dms_cloudwatch_log_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 2.0"

  trusted_role_actions=[  "sts:AssumeRole"
  ]
  trusted_role_services = ["dms.amazonaws.com",
  ]
  create_role = true

  role_name         = "dms-cloudwatch-logs-role"
  role_requires_mfa = false

  custom_role_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonDMSCloudWatchLogsRole"]
}

module "glue_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 2.0"

  trusted_role_actions=[  "sts:AssumeRole"
  ]
  trusted_role_services =  var.list_glue_trusted_service
  create_role = true

  role_name         = "glue-service"
  role_requires_mfa = false

  custom_role_policy_arns = var.list_glue_iam_roles
}



### wait couple minutes before iam role and attachments get effective
resource "time_sleep" "wait" {
	depends_on = [module.dms_cloudwatch_log_role,module.dms_vpc_role,module.glue_role]
	create_duration = "2m"
    destroy_duration = "2m"

}
##################################################################################
# RESOURCES
##################################################################################

##################################################################################
#SECURITY GROUP FOR MSSQL
##################################################################################

module "security_group_mssql" {
  source  = "terraform-aws-modules/security-group/aws//modules/mssql"
  name  = "sql-dms"
  vpc_id = var.vpc_id
  ingress_cidr_blocks = var.mssql_ingress_cidr_blocks
}

##################################################################################
# SECURITY GROUP FOR MSSQL
##################################################################################


module "security_group_mysql" {
  source  = "terraform-aws-modules/security-group/aws//modules/mysql"
  name  = "sugar-dms"
  vpc_id = var.vpc_id
  ingress_cidr_blocks =  var.mysql_ingress_cidr_blocks
}


##################################################################################
# CREATE S3 BUCKET
##################################################################################



data "aws_s3_bucket" "s3_bucket_raw" {
  bucket = var.raw_bucket_name
}

##################################################################################
# CREATE SUBNET GROUP FOR DMS
##################################################################################

data "aws_subnet_ids" "selected_vpc" {
  vpc_id = var.vpc_id
}

data "aws_subnet" "subnet_list" {
  for_each = data.aws_subnet_ids.selected_vpc.ids
  id       = each.value
}


resource "aws_dms_replication_subnet_group" "dms-subnet" {
  replication_subnet_group_description = "Replication subnet group"
  replication_subnet_group_id          = "dms-replication-subnet-group-tf"

  subnet_ids = [for s in data.aws_subnet.subnet_list : s.id]
  depends_on = [time_sleep.wait]
}


##################################################################################
# REPLICATION INSTANCE
#################################################################################

resource "aws_dms_replication_instance" "dms-instance" {
  allocated_storage = var.allocated_storage
  apply_immediately = true
  auto_minor_version_upgrade = true
  preferred_maintenance_window = "sun:00:30-sun:04:30"
  publicly_accessible = false
  replication_instance_class = var.replication_instance_class
  replication_instance_id = var.replication_instance_id
  replication_subnet_group_id = aws_dms_replication_subnet_group.dms-subnet.id
  vpc_security_group_ids = [
    module.security_group_mssql.this_security_group_id,
    module.security_group_mysql.this_security_group_id]
  depends_on = [time_sleep.wait]
}

##################################################################################
# SOURCE
#################################################################################

resource "aws_dms_endpoint" "source_endpoints" {

  for_each = var.endpoints_list

  endpoint_id = each.key
  endpoint_type = each.value.endpoint_type
  engine_name = each.value.engine_name
  certificate_arn = lookup(each.value, "certificate_arn", "")
  database_name = lookup(each.value, "database_name", "")


  extra_connection_attributes = lookup(each.value, "extra_connection_attributes", "")
  kms_key_arn = lookup(each.value, "kms_key_arn", "")
  username = lookup(each.value, "username", "")
  password = lookup(each.value, "password", "")
  port = lookup(each.value, "port", null)
  server_name = lookup(each.value, "server_name", "")
  ssl_mode = lookup(each.value, "ssl_mode", "none")
  service_access_role = lookup(each.value, "service_access_role", "")


  dynamic "s3_settings" {
    # The [*] here will test if the variable value is set. If so, it'll
    # produce a single-element list. If not (if it's null), it'll produce
    # an empty list.
    for_each = lookup(each.value, "source_s3_settings", var.source_s3_settings)[*]
    content {
      bucket_folder = s3_settings.value.bucket_folder
      bucket_name = data.aws_s3_bucket.s3_bucket_raw.id
      compression_type = lookup(s3_settings.value, "compression_type", "GZIP")
      service_access_role_arn = s3_settings.value.service_access_role_arn
      external_table_definition = lookup(s3_settings.value, "external_table_definition", "")
      csv_row_delimiter = lookup(s3_settings.value, "csv_row_delimiter", "\\n")
      csv_delimiter = lookup(s3_settings.value, "csv_delimiter ", ",")
    }
  }

  tags = merge ({
    Terraform-Name = format("%s", each.key)
  },
  lookup(each.value, "tags", {}),
  {
    parent_directory = each.value.parent_directory
    target_subsequent_folder = each.value.target_subsequent_folder
    glue_database_name = each.value.glue_database_name

  })

}
##################################################################################
# TARGET
#################################################################################


resource "aws_dms_endpoint" "s3_target_endpoints" {

  for_each = aws_dms_endpoint.source_endpoints

  endpoint_id = "s3raw-${each.key}"
  endpoint_type = "target"
  engine_name = "s3"

  s3_settings {
    bucket_folder = "${each.value.tags.parent_directory}/${each.value.engine_name}${each.value.tags.target_subsequent_folder}"
    bucket_name = data.aws_s3_bucket.s3_bucket_raw.id
    compression_type = var.target_s3_settings.compression_type
    service_access_role_arn = module.glue_role.this_iam_role_arn
    external_table_definition = var.target_s3_settings.external_table_definition
    #	  csv_row_delimiter 			= var.target_s3_settings.csv_row_delimiter
    #	  csv_delimiter 				= var.target_s3_settings.csv_delimiter
  }
  extra_connection_attributes = var.target_s3_settings.extra_connection_attributes

  ## s3 endpoint terraform is missing extra connection settings, use local-exec to complete setup in 1 sitting. ref: https://github.com/terraform-providers/terraform-provider-aws/issues/8009
  provisioner "local-exec" {
    #	command = "aws dms modify-endpoint --endpoint-arn ${self.endpoint_arn} --s3-settings ${var.target_s3_settings.extra_s3_attributes_cli},BucketName=${var.target_s3_settings.bucket_name},BucketFolder=${each.value.tags.parent_directory}/${each.value.engine_name}${each.value.tags.target_subsequent_folder} --profile ${var.profile} "
    command = "aws dms modify-endpoint --endpoint-arn ${self.endpoint_arn} --s3-settings ${var.target_s3_settings.extra_s3_attributes_cli},BucketName=${data.aws_s3_bucket.s3_bucket_raw.id},BucketFolder=${each.value.tags.parent_directory}/${each.value.engine_name}${each.value.tags.target_subsequent_folder} --region ${var.region} "

  }

  tags = {
    Terraform-Name = format("%s", each.key)
  }
  depends_on = [
    aws_dms_endpoint.source_endpoints,
  ]

}


##################################################################################
# REPLICATION TASKS
#################################################################################

resource "aws_dms_replication_task" "replication_tasks" {
  for_each = aws_dms_endpoint.source_endpoints
  replication_task_id = "rep-${each.key}"
  cdc_start_time = null
  migration_type = "full-load-and-cdc"
  replication_instance_arn = aws_dms_replication_instance.dms-instance.replication_instance_arn

  replication_task_settings = jsonencode(var.replication_task_settings)
  source_endpoint_arn = each.value.endpoint_arn
#  table_mappings = jsonencode (lookup(each.value, "table_mapping_rule", var.table_mapping_default))
  table_mappings = jsonencode (lookup(var.endpoints_list[each.key],"table_mapping_rule",var.table_mapping_default))


  lifecycle {
    ignore_changes = [
      ### Terraform doesn't understand logging name is specified later on
      replication_task_settings,
    ]
  }
  provisioner "local-exec" {
      when    = destroy
      command = "aws dms stop-replication-task --replication-task-arn ${self.replication_task_arn} --region us-east-1"
      on_failure = continue ## fail mean tasks not running, continue to destroy
    }
  provisioner "local-exec" {
    command = "aws dms start-replication-task --replication-task-arn ${self.replication_task_arn} --start-replication-task-type start-replication --region us-east-1"
    on_failure = continue ## fail mean tasks not ready, have to trigger manually
  }

  tags = {
    Source = each.key
    Target = "${aws_dms_endpoint.s3_target_endpoints["${each.key}"].endpoint_id}"
  }
  target_endpoint_arn = aws_dms_endpoint.s3_target_endpoints[each.key].endpoint_arn
  depends_on = [
    aws_dms_replication_instance.dms-instance,
    aws_dms_endpoint.source_endpoints,
    aws_dms_endpoint.s3_target_endpoints,
    time_sleep.wait
  ]
}

##################################################################################
# GLUE DATABASE CATALOG
#################################################################################

resource "aws_glue_catalog_database" "aws_glue_catalog_database" {
  for_each = aws_dms_endpoint.source_endpoints
  name = each.value.tags.glue_database_name
}

##################################################################################
# GLUE CRAWLER FOR S3 Target
#################################################################################

resource "aws_glue_crawler" "crawler" {
  for_each = aws_dms_endpoint.source_endpoints
  database_name = each.value.tags.glue_database_name
  name = "${each.key}-crawler"
  role = module.glue_role.this_iam_role_arn
  schedule = var.schedule
  schema_change_policy {
    delete_behavior = "DEPRECATE_IN_DATABASE"
    update_behavior = "UPDATE_IN_DATABASE"
  }
  s3_target {
    path = "s3://${data.aws_s3_bucket.s3_bucket_raw.id}/${each.value.tags.parent_directory}/${each.value.engine_name}${each.value.tags.target_subsequent_folder}"
  }
  depends_on = [
    aws_dms_endpoint.s3_target_endpoints,
  ]

}

resource "aws_sns_topic" "dms_failure" {
  name = "dms-task-failure-topic"
}

resource "aws_dms_event_subscription" "task_sub" {
  enabled          = true
  source_type      = "replication-task"
  event_categories = ["failure"]
  name             = "task-event-subscription"
  sns_topic_arn    = aws_sns_topic.dms_failure.arn
  source_ids       = [for s in aws_dms_replication_task.replication_tasks : s.replication_task_id]
}

resource "aws_dms_event_subscription" "dms_instance_sub" {
  enabled          = true
  source_type      = "replication-instance"
  event_categories = ["failure"]
  name             = "instance-event-subscription"
  sns_topic_arn    = aws_sns_topic.dms_failure.arn
  source_ids       = [aws_dms_replication_instance.dms-instance.id]
}