# OpenCTI AWS Deployment

This Terraform project deploys OpenCTI (Open Cyber Threat Intelligence Platform) on AWS using ECS Fargate with a modular architecture, following best practices for cost efficiency and security.

## Architecture Overview

The deployment uses a modern, serverless architecture with AWS managed services:

```text
┌─────────────────────────────────────────────────────────────────┐
│                        Internet Gateway                        │
└─────────────────────┬───────────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────────┐
│                Application Load Balancer                       │
│                    (Public Subnets)                            │
└─────────────────────┬───────────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────────┐
│                    ECS Fargate Cluster                         │
│                   (Private Subnets)                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │
│  │   OpenCTI   │  │   Worker    │  │   Worker    │            │
│  │  Platform   │  │  (3x)       │  │  (3x)       │            │
│  └─────────────┘  └─────────────┘  └─────────────┘            │
└─────────────────────┬───────────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────────┐
│                    AWS Managed Services                        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │
│  │ ElastiCache │  │  Amazon MQ  │  │ OpenSearch  │            │
│  │    Redis    │  │  RabbitMQ   │  │             │            │
│  └─────────────┘  └─────────────┘  └─────────────┘            │
│  ┌─────────────┐  ┌─────────────┐                             │
│  │     S3      │  │     EFS     │                             │
│  │   Storage   │  │  Filesystem │                             │
│  └─────────────┘  └─────────────┘                             │
└─────────────────────────────────────────────────────────────────┘
```

## Core Components

### **Networking Layer**

- **VPC** with public and private subnets across 2 AZs
- **Internet Gateway** for external access
- **NAT Gateway** for outbound internet access from private subnets
- **Security Groups** with least privilege access
- **Route Tables** for proper traffic routing

### **Compute Layer**

- **ECS Fargate Cluster** for serverless container orchestration
- **Application Load Balancer** for external access and health checks
- **Cloud Map** for internal service discovery (OpenCTI only)

### **Storage Layer**

- **EFS** for persistent filesystem storage (replaces RDS)
- **S3** for object storage (replaces MinIO)
- **ElastiCache Redis** for caching and session storage
- **OpenSearch** for search and analytics
- **Amazon MQ RabbitMQ** for message queuing

### **Application Layer**

- **OpenCTI Platform** (main application, 1 instance)
- **Worker Services** (background processing, 3 instances)
- **Health Checks** at both container and ALB levels

## Managed Services Configuration

### **ElastiCache Redis**

- **Instance Type**: `cache.t3.micro`
- **Engine**: Redis 7.x
- **Configuration**: Single node, encryption at rest
- **Purpose**: Caching and session storage

### **Amazon MQ RabbitMQ**

- **Instance Type**: `mq.t3.micro`
- **Engine**: RabbitMQ 3.13
- **Configuration**: SSL enabled, management console available
- **Purpose**: Message queuing for background processing

### **OpenSearch**

- **Instance Type**: `t3.small.search`
- **Engine**: OpenSearch 2.11
- **Configuration**: Single node, encryption enabled
- **Purpose**: Search and analytics

### **S3 Storage**

- **Configuration**: Versioning enabled, encryption at rest
- **Access**: IAM roles (no access keys)
- **Purpose**: Object storage for OpenCTI data

### **EFS Filesystem**

- **Configuration**: Encrypted, provisioned throughput
- **Access**: EFS access point with proper permissions
- **Purpose**: Persistent filesystem storage

## Module Structure

The project is organized into four main modules:

- **networking** - VPC, subnets, security groups, and networking components
- **storage** - S3 bucket, EFS file system, ElastiCache Redis, OpenSearch, and Amazon MQ
- **compute** - ECS cluster, ALB, Cloud Map, and IAM roles
- **services** - OpenCTI application services and task definitions

## Prerequisites

1. AWS CLI configured with appropriate permissions
2. OpenTofu (or Terraform) installed
3. Valid AWS credentials (SSO profile recommended)
4. IAM permissions to create ECS, VPC, S3, ElastiCache, OpenSearch, Amazon MQ, and other AWS resources

## Deployment

1. **Clone and configure:**

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

2. **Initialize and deploy:**

   ```bash
   tofu init
   tofu plan
   tofu apply
   ```

3. **Access OpenCTI:**

   - URL: Check the output `opencti_url`
   - Default credentials: `admin@opencti.io` / `changeme`

4. **Force new deployment (if needed):**

   ```bash
   aws ecs update-service \
     --cluster opencti-demo-cluster \
     --service opencti-demo-opencti \
     --force-new-deployment \
     --profile kai-labs \
     --region us-east-1
   ```

## Cost Optimization

This deployment is optimized for demo/testing with:

- **Small instance types**: `t3.micro` (Redis, RabbitMQ), `t3.small.search` (OpenSearch)
- **Single AZ deployment**: Cost-effective for demo environments
- **Minimal storage**: 20GB OpenSearch, provisioned EFS throughput
- **7-day log retention**: CloudWatch logs with short retention
- **Fargate**: Pay only for running containers
- **Managed services**: No EC2 instances to manage

## Security Features

- **Network isolation**: All services run in private subnets
- **Security groups**: Least privilege access between services
- **Encryption**: All storage encrypted at rest (EFS, S3, ElastiCache, OpenSearch)
- **SSL/TLS**: RabbitMQ and OpenSearch use encrypted connections
- **IAM roles**: S3 access via IAM roles, no access keys
- **No direct internet access**: ALB as single entry point
- **VPC endpoints**: Secure communication with AWS services

## Monitoring

- CloudWatch Logs for all services
- ECS Container Insights enabled
- Health checks configured for all services

## Cleanup

To destroy all resources:

```bash
tofu destroy
```

## Health Check Architecture

The deployment uses a multi-layered health check approach:

- **ALB Health Checks**: Load balancer checks `/health` endpoint on port 8080
- **Container Health Checks**: ECS checks `localhost:8080/health` from within containers
- **Service Discovery**: OpenCTI uses Cloud Map for internal DNS resolution
- **Dependency Management**: Services start in order (OpenCTI → Workers)
- **Managed Services**: Redis, RabbitMQ, and OpenSearch are AWS managed with built-in health checks

## Service Communication

- **OpenCTI ↔ Redis**: Direct connection to ElastiCache endpoint
- **OpenCTI ↔ RabbitMQ**: SSL connection to Amazon MQ endpoint
- **OpenCTI ↔ OpenSearch**: HTTPS connection to OpenSearch endpoint
- **OpenCTI ↔ S3**: IAM role-based access for object storage
- **OpenCTI ↔ EFS**: NFS mount for persistent filesystem storage
- **Workers ↔ OpenCTI**: HTTP connection via Cloud Map service discovery

## Key Features

- **Serverless Architecture**: All services run on ECS Fargate (no EC2 instances)
- **AWS Managed Services**: Redis, RabbitMQ, OpenSearch, and S3 are fully managed
- **Official Docker Images**: Uses `opencti/platform:6.7.20` and `opencti/worker:6.7.20`
- **IAM Role-Based Access**: S3 access via IAM roles, no access keys needed
- **Encrypted Storage**: All data encrypted at rest and in transit
- **Modular Design**: Four separate modules for easy maintenance and updates
- **Cost Optimized**: Small instance types and single AZ for demo environments
- **Production Ready**: Can be scaled up by changing instance types and adding AZs

## Environment Variables

- **Admin Configuration**: Email, password, and token automatically generated
- **Service Endpoints**: All managed service endpoints automatically configured
- **SSL/TLS**: RabbitMQ and OpenSearch use encrypted connections
- **Logging**: Configured for error level with CloudWatch integration
- **Health Checks**: Proper health check configuration for container and ALB levels
