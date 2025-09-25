# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Terraform project that deploys OpenCTI (Open Cyber Threat Intelligence Platform) on AWS using ECS Fargate with a modular architecture. The deployment uses OpenTofu/Terraform to provision infrastructure across four main modules.

## Development Commands

### Infrastructure Management
- **Initialize Terraform:** `tofu init` (OpenTofu preferred) or `terraform init`
- **Plan deployment:** `tofu plan`
- **Apply changes:** `tofu apply`
- **Destroy infrastructure:** `tofu destroy`
- **Format Terraform files:** `tofu fmt` or `terraform fmt`
- **Validate configuration:** `tofu validate` or `terraform validate`

### Configuration
- **Create configuration:** `cp terraform.tfvars.example terraform.tfvars`
- Edit `terraform.tfvars` with appropriate values for your deployment

## Architecture Overview

### Module Structure
The project uses a modular architecture with four main components:

1. **networking** (`modules/networking/`)
   - VPC with public/private subnets across 2 AZs
   - Security groups for different service tiers
   - NAT gateways for private subnet internet access

2. **storage** (`modules/storage/`)
   - S3 bucket for object storage
   - EFS file system for persistent storage
   - ElastiCache Redis cluster
   - OpenSearch domain

3. **compute** (`modules/compute/`)
   - ECS Fargate cluster
   - Application Load Balancer
   - Cloud Map service discovery
   - IAM roles and policies

4. **services** (`modules/services/`)
   - OpenCTI platform service
   - Redis service (if not using ElastiCache)
   - RabbitMQ service
   - Worker services (3 replicas)

### Service Architecture
- All services run on ECS Fargate (no EC2 instances)
- Internal communication via Cloud Map service discovery
- External access through ALB only
- Multi-layered health checks (ALB + container level)
- Services start in dependency order: Redis → RabbitMQ → OpenCTI → Workers

## Key Variables

Default configuration is optimized for demo/testing environments:
- `aws_region`: Target AWS region (default: us-east-1)
- `aws_profile`: AWS CLI profile name
- `project_name`: Project identifier (default: opencti)
- `environment`: Environment name (default: demo)
- `vpc_cidr`: VPC network range (default: 10.0.0.0/16)
- `opencti_admin_email`: Admin user email
- `opencti_admin_password`: Admin password (marked sensitive)

## Security Configuration

- All application services run in private subnets
- Security groups follow least privilege principles
- Encrypted storage for all data services
- IAM roles used for AWS service access (no access keys)
- ALB serves as single entry point

## Important Implementation Details

- Uses OpenTofu as preferred Terraform alternative
- No RDS database - uses filesystem storage on EFS
- S3 access via IAM roles attached to ECS tasks
- Health checks use `localhost` for container-level checks
- Service discovery hostnames: `redis.local`, `rabbitmq.local`, etc.
- Persistent data stored on EFS with access points
- CloudWatch Logs with 7-day retention for cost optimization

## Terraform Provider Requirements

- AWS provider ~> 5.0
- Random provider ~> 3.1
- Minimum Terraform version: >= 1.0