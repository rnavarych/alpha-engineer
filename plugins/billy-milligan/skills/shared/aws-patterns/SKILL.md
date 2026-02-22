---
name: aws-patterns
description: |
  AWS production patterns: ECS Fargate with Terraform, VPC 3-tier architecture, IAM least
  privilege with OIDC (no long-lived credentials), ALB + target groups, RDS Multi-AZ,
  ElastiCache cluster, S3 lifecycle policies, CloudWatch alarms, Secrets Manager rotation.
  Use when designing AWS architecture, writing Terraform for AWS, reviewing IAM policies.
allowed-tools: Read, Grep, Glob
---

# AWS Production Patterns

## When to Use This Skill
- Designing VPC and network architecture
- Writing Terraform for ECS/RDS/ElastiCache
- Setting up IAM with least privilege
- Configuring ALB and target groups
- Managing secrets with AWS Secrets Manager

## Core Principles

1. **VPC 3-tier: public/private/data** — load balancers in public, app in private, databases in data subnet; no DB in public
2. **IAM least privilege** — no wildcard `*` resources in production policies; scope to specific ARNs
3. **No long-lived credentials** — use IAM roles for EC2/ECS/Lambda; OIDC for GitHub Actions
4. **Multi-AZ everything** — RDS Multi-AZ, ElastiCache replication group, ALB spans 3 AZs
5. **Secrets Manager over Parameter Store for secrets** — automatic rotation, versioning, cross-account access

---

## Patterns ✅

### VPC 3-Tier Architecture (Terraform)

```hcl
# Three tiers: public (ALB), private (app), data (RDS/ElastiCache)

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "production-vpc"
  cidr = "10.0.0.0/16"

  azs              = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnets   = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]   # ALB
  private_subnets  = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"] # App (ECS)
  database_subnets = ["10.0.20.0/24", "10.0.21.0/24", "10.0.22.0/24"] # RDS, Redis

  enable_nat_gateway     = true
  single_nat_gateway     = false  # One NAT per AZ for HA (costs ~$32/month each)
  enable_dns_hostnames   = true

  # Tag subnets for EKS/ECS discovery
  public_subnet_tags  = { "kubernetes.io/role/elb" = "1" }
  private_subnet_tags = { "kubernetes.io/role/internal-elb" = "1" }
}
```

### ECS Fargate Service

```hcl
resource "aws_ecs_cluster" "main" {
  name = "production"

  setting {
    name  = "containerInsights"
    value = "enabled"  # CloudWatch Container Insights
  }
}

resource "aws_ecs_task_definition" "order_service" {
  family                   = "order-service"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512    # 0.5 vCPU
  memory                   = 1024   # 1 GB

  execution_role_arn = aws_iam_role.ecs_task_execution.arn  # Pull image, write logs
  task_role_arn      = aws_iam_role.order_service_task.arn  # App permissions

  container_definitions = jsonencode([{
    name  = "order-service"
    image = "${aws_ecr_repository.order_service.repository_url}:${var.image_tag}"

    portMappings = [{ containerPort = 3000 }]

    environment = [
      { name = "NODE_ENV", value = "production" }
    ]

    secrets = [
      {
        name      = "DATABASE_URL"
        valueFrom = "arn:aws:secretsmanager:us-east-1:123456789:secret:prod/order-service/db-url"
      }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/order-service"
        "awslogs-region"        = "us-east-1"
        "awslogs-stream-prefix" = "ecs"
      }
    }

    healthCheck = {
      command     = ["CMD-SHELL", "curl -f http://localhost:3000/health/live || exit 1"]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 60
    }
  }])
}

resource "aws_ecs_service" "order_service" {
  name            = "order-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.order_service.arn
  desired_count   = 3
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = module.vpc.private_subnets  # Private subnet — no public IP
    security_groups  = [aws_security_group.order_service.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.order_service.arn
    container_name   = "order-service"
    container_port   = 3000
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true  # Auto-rollback on deployment failure
  }

  deployment_minimum_healthy_percent = 100  # Zero-downtime
  deployment_maximum_percent         = 200
}
```

### IAM Least Privilege (No Wildcards)

```hcl
# Task role: what the application can do
resource "aws_iam_role_policy" "order_service_task" {
  name = "order-service-permissions"
  role = aws_iam_role.order_service_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          "arn:aws:secretsmanager:us-east-1:123456789:secret:prod/order-service/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = [aws_sqs_queue.order_events.arn]
        # Scoped to specific queue ARN — not all SQS
      },
      {
        Effect = "Allow"
        Action = ["s3:PutObject", "s3:GetObject"]
        Resource = ["${aws_s3_bucket.order_attachments.arn}/*"]
        # Scoped to specific bucket prefix — not all S3
      }
    ]
  })
}

# GitHub Actions OIDC — no long-lived credentials
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

resource "aws_iam_role" "github_actions_deploy" {
  name = "github-actions-deploy"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:myorg/myrepo:*"
        }
      }
    }]
  })
}
```

### RDS Multi-AZ (PostgreSQL)

```hcl
resource "aws_db_instance" "postgres" {
  identifier        = "production-postgres"
  engine            = "postgres"
  engine_version    = "16.2"
  instance_class    = "db.t4g.medium"  # ARM-based, 20% cheaper than x86
  allocated_storage = 100
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = "orderdb"
  username = "postgres"
  password = random_password.db_password.result

  multi_az               = true   # Standby in another AZ; 20s failover
  backup_retention_period = 7     # 7 days of automated backups
  backup_window          = "03:00-04:00"
  maintenance_window     = "Mon:04:00-Mon:05:00"

  deletion_protection = true       # Require explicit disable to delete
  skip_final_snapshot = false
  final_snapshot_identifier = "production-postgres-final"

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name  # Data subnets only

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  performance_insights_enabled = true
  monitoring_interval          = 60  # Enhanced monitoring every 60s
  monitoring_role_arn          = aws_iam_role.rds_monitoring.arn
}
```

---

## Anti-Patterns ❌

### Database in Public Subnet
**What it is**: RDS instance with `publicly_accessible = true` in public subnet.
**What breaks**: Database directly accessible from internet. Brute force, credential stuffing, data exfiltration.
**Fix**: Databases in data subnet (private, no internet route). Access only from app subnet security group.

### IAM User Credentials in Code/CI
**What it is**: `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` as environment variables in CI.
**What breaks**: Key leaked in log → attacker has persistent access. Key rotation requires updating every pipeline.
**Fix**: OIDC for GitHub Actions. IAM roles for ECS/Lambda/EC2. No long-lived credentials.

### Single AZ Deployment
**What it is**: All ECS tasks, RDS, and ElastiCache in one availability zone.
**What breaks**: AZ outage (happens ~twice per year per AWS SLA) = full service outage.
**Fix**: Multi-AZ RDS, ElastiCache replication group, ECS service spanning 3 AZs, ALB in 3 AZs.

---

## Quick Reference

```
VPC: public (ALB), private (app), data (DB/cache) — never DB in public
Fargate CPU: 256, 512, 1024, 2048, 4096 (in units; 1024 = 1 vCPU)
RDS: Multi-AZ=true, backup_retention=7, deletion_protection=true
IAM: no wildcards; scope to specific ARNs; OIDC for CI/CD
ECS rolling: minimum_healthy=100, maximum=200, circuit_breaker=true
Secrets: Secrets Manager (rotation) vs Parameter Store (config)
OIDC: GitHub Actions → no long-lived AWS credentials
S3 lifecycle: Standard → Standard-IA (30d, 60% cheaper) → Glacier (90d, 96% cheaper)
CloudWatch alarms: CPUUtilization >80%, FreeStorageSpace <5GB, UnHealthyHostCount >0
```
