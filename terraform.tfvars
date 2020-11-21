region = "us-east-1"
##################################################################################
# NETWORK - TODO: get IP address of MySQL and SQL; get VPC that DMS run in
#################################################################################

mssql_ingress_cidr_blocks = ["10.10.10.10/0"]
mysql_ingress_cidr_blocks = ["10.10.10.11/0"]
vpc_id = "vpc-xxxx"

##################################################################################
# GLUE IAM Assume roles
#################################################################################
list_glue_trusted_service = ["glue.amazonaws.com",
	"dms.amazonaws.com",
	"s3.amazonaws.com"
]

list_glue_iam_roles = ["arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole",
	"arn:aws:iam::aws:policy/AWSLakeFormationDataAdmin",
	"arn:aws:iam::aws:policy/AmazonS3FullAccess",
]


##################################################################################
# DMS VARIABLES
#################################################################################
allocated_storage = 200

replication_instance_class = "dms.t2.large"
replication_instance_id = "dms-instance"
crawler_schedule = "cron(15 4 * * ? *)"

##################################################################################
# S3 TARGET endpoint - TODO:put force_destroy_s3 to FALSE when deploy in TEST/PROD
#################################################################################
raw_bucket_name = "xxx-datalake-raw"



##################################################################################
# SOURCE VARIABLES TODO: replace token with user/pass in pipelines
#################################################################################


source_s3_settings  = null


endpoints_list = {
	test-databasename2 = {
		glue_database_name = "test_databasename2"
		parent_directory = "parent_dicrectory"
		database_name = "databasename2"
		target_subsequent_folder = "/test/databasename2"
		endpoint_type = "source"
		engine_name ="sqlserver"
		"server_name": "10.10.10.10\\DATA01"
		"username"= "#{sqlusername}#"
		"password"= "#{sqlpassword}#"
		"port"= 1433
		"table_mapping_rule"= {
			"rules": [
				{
					"rule-type": "selection",
					"rule-id": "1",
					"rule-name": "1",
					"rule-action": "include",
					"object-locator": {
						"schema-name": "dbo",
						"table-name": "%"
					}
				},
				{
					"rule-type": "selection",
					"rule-id": "2",
					"rule-name": "2",
					"object-locator": {
						"schema-name": "history",
						"table-name": "%"
					},
					"rule-action": "exclude"
				},
				{
					"rule-type": "transformation",
					"rule-id": "3",
					"rule-name": "3",
					"rule-action": "add-column",
					"rule-target": "column",
					"object-locator": {
						"schema-name": "%",
						"table-name": "%"
					},
					"value": "environmentid",
					"expression": -1
					"data-type": {
						"type": "int1",
					}
				}
			]
		}
	}

	test-databasename = {
		glue_database_name = "test_databasename"
		parent_directory = "parent_dicrectory"
		database_name = "databasename"
		##Server name (DEV/TEST,TEST2, PROD1,PROD2,PILOT) follow by schema/database_name
		target_subsequent_folder = "/test/databasename"
		endpoint_type = "source"
		engine_name ="sqlserver"
		"server_name": "10.10.10.10\\DATABASE"
		"username"= "#{sqlusername}#"
		"password"= "#{sqlpassword}#"
		"port"= 1433
		"table_mapping_rule"= {
			"rules": [
				{
					"rule-type": "selection",
					"rule-id": "1",
					"rule-name": "1",
					"rule-action": "include",
					"object-locator": {
						"schema-name": "dbo",
						"table-name": "%"
					}
				},
				{
					"rule-type": "selection",
					"rule-id": "2",
					"rule-name": "2",
					"object-locator": {
						"schema-name": "history",
						"table-name": "%"
					},
					"rule-action": "exclude"
				},
				{
					"rule-type": "transformation",
					"rule-id": "3",
					"rule-name": "3",
					"rule-action": "add-column",
					"rule-target": "column",
					"object-locator": {
						"schema-name": "%",
						"table-name": "%"
					},
					"value": "environmentid",
					"expression": -1
					"data-type": {
						"type": "int1",
					}
				}
			]
		}
	}
	sandbox-mysql = {
		glue_database_name = "sandbox_mysql"
		parent_directory = "soft"
		database_name = "mysql_database"
4		target_subsequent_folder = "/sandbox"
		endpoint_type = "source"
		engine_name ="mysql"
		"server_name": "xxxx.us-east-1.rds.amazonaws.com"
		"username"= "#{mysqlusername}#"
		"password"= "#{mysqlpassword}#"
		"port"= 3306
		"table_mapping_rule"={
			"rules": [
				{
					"rule-type": "selection",
					"rule-id": "1",
					"rule-name": "1",
					"rule-action": "include",
					"object-locator": {
						"schema-name": "test",
						"table-name": "%"
					}
				}
			]
		}
	}

}