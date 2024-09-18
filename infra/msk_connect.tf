
resource "aws_s3_bucket" "this" {
  bucket = "${local.prefix}-msk-connectors-plugins-${random_string.this.result}"

  tags = {
    Name = "MSK Connect Plugins"
  }
}

resource "aws_s3_object" "this" {
  bucket = aws_s3_bucket.this.id
  key    = "debezium-connector-sqlserver-2.7.2.Final-plugin.zip"
  source = "../bin/debezium-connector-sqlserver-2.7.2.Final-plugin.zip"
  etag   = filemd5("../bin/debezium-connector-sqlserver-2.7.2.Final-plugin.zip")
}

resource "aws_mskconnect_custom_plugin" "this" {
  name         = "${local.prefix}-debezium-sqlserver"
  description  = "Debezium Microsoft SQL Server Plugin v2.7.2"
  content_type = "ZIP"

  location {
    s3 {
      bucket_arn = aws_s3_bucket.this.arn
      file_key   = aws_s3_object.this.key
    }
  }
}

resource "aws_security_group" "debezium" {
  name        = "${local.prefix}-msk-connector-debezium-sg"
  description = "MSK security group"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_cloudwatch_log_group" "this" {
  name         = "/${local.prefix}/msk-connectors/debezium"
  skip_destroy = false
}

data "aws_msk_bootstrap_brokers" "this" {
  cluster_arn = aws_msk_serverless_cluster.this.arn
}

resource "aws_mskconnect_connector" "this" {
  name                       = "${local.prefix}-debezium-sqlserver"
  kafkaconnect_version       = "2.7.1"
  service_execution_role_arn = element(module.iamsr.role_arn, 1)
  connector_configuration = {
    "connector.class"                                 = "io.debezium.connector.sqlserver.SqlServerConnector",
    "database.hostname"                               = aws_db_instance.this.address,
    "database.port"                                   = aws_db_instance.this.port,
    "database.user"                                   = local.username,
    "database.password"                               = local.password,
    "database.names"                                  = "Demo",
    "database.encrypt"                                = false,
    "topic.prefix"                                    = "fullfillment",
    "table.include.list"                              = "dbo.Example",
    "schema.history.internal.kafka.bootstrap.servers" = data.aws_msk_bootstrap_brokers.this.bootstrap_brokers_sasl_iam,
    "schema.history.internal.kafka.topic"             = "schemahistory.fullfillment",
    "tasks.max"                                       = 3,
    "bootstrap.servers"                               = data.aws_msk_bootstrap_brokers.this.bootstrap_brokers_sasl_iam,
  }

  capacity {
    autoscaling {
      mcu_count        = 1
      min_worker_count = 1
      max_worker_count = 2
      scale_in_policy {
        cpu_utilization_percentage = 20
      }
      scale_out_policy {
        cpu_utilization_percentage = 80
      }
    }
  }

  kafka_cluster {
    apache_kafka_cluster {
      bootstrap_servers = data.aws_msk_bootstrap_brokers.this.bootstrap_brokers_sasl_iam
      vpc {
        security_groups = [aws_security_group.debezium.id]
        subnets         = aws_subnet.private[*].id
      }
    }
  }

  kafka_cluster_client_authentication {
    authentication_type = "IAM"
  }

  kafka_cluster_encryption_in_transit {
    encryption_type = "TLS"
  }

  plugin {
    custom_plugin {
      arn      = aws_mskconnect_custom_plugin.this.arn
      revision = aws_mskconnect_custom_plugin.this.latest_revision
    }
  }

  log_delivery {
    worker_log_delivery {
      cloudwatch_logs {
        enabled   = true
        log_group = aws_cloudwatch_log_group.this.name
      }
    }
  }

  timeouts {
    create = "20m"
    update = "20m"
    delete = "20m"
  }

}
