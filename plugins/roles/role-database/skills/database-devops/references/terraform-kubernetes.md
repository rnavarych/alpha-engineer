# Terraform Database Provisioning

## When to load
Load when provisioning database infrastructure as code with Terraform (AWS RDS, Google Cloud SQL, MongoDB Atlas).

## Terraform

### AWS RDS PostgreSQL
```hcl
resource "aws_db_instance" "main" {
  identifier     = "myapp-production"
  engine         = "postgres"
  engine_version = "16.2"
  instance_class = "db.r6g.xlarge"

  allocated_storage     = 100
  max_allocated_storage = 500
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id           = aws_kms_key.rds.arn

  db_name  = "myapp"
  username = "admin"
  password = data.aws_secretsmanager_secret_version.db_password.secret_string

  multi_az               = true
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  backup_retention_period = 14
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  performance_insights_enabled = true
  monitoring_interval         = 60
  monitoring_role_arn         = aws_iam_role.rds_monitoring.arn
  parameter_group_name        = aws_db_parameter_group.pg16.name
  deletion_protection         = true
}

resource "aws_db_parameter_group" "pg16" {
  family = "postgres16"
  name   = "myapp-pg16"
  parameter {
    name  = "shared_preload_libraries"
    value = "pg_stat_statements,auto_explain"
  }
  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }
}
```

### Google Cloud SQL
```hcl
resource "google_sql_database_instance" "main" {
  name             = "myapp-production"
  database_version = "POSTGRES_16"
  region           = "us-central1"
  settings {
    tier              = "db-custom-4-16384"
    availability_type = "REGIONAL"
    disk_size         = 100
    disk_type         = "PD_SSD"
    disk_autoresize   = true
    backup_configuration {
      enabled                        = true
      point_in_time_recovery_enabled = true
      backup_retention_settings { retained_backups = 14 }
    }
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.vpc.id
    }
    database_flags { name = "log_min_duration_statement"; value = "1000" }
  }
  deletion_protection = true
}
```

### MongoDB Atlas
```hcl
resource "mongodbatlas_cluster" "main" {
  project_id                  = mongodbatlas_project.myproject.id
  name                        = "production"
  provider_name               = "AWS"
  provider_region_name        = "US_EAST_1"
  provider_instance_size_name = "M30"
  cluster_type                = "REPLICASET"
  replication_specs {
    num_shards = 1
    regions_config {
      region_name     = "US_EAST_1"
      electable_nodes = 3
      priority        = 7
    }
  }
  auto_scaling_compute_enabled            = true
  auto_scaling_compute_scale_down_enabled = true
  backup_enabled                          = true
  pit_enabled                             = true
  encryption_at_rest_provider             = "AWS"
}
```

