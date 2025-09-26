# OpenCTI AWS Deployment: Considerations & Lessons Learned

## Executive Summary

This document outlines the key considerations, challenges, and lessons learned during the deployment of OpenCTI (Open Cyber Threat Intelligence Platform) on AWS using a serverless, managed services architecture.

## Architecture Decisions

### ✅ **Successful Decisions**

#### **1. AWS Managed Services Approach**
- **Decision**: Use AWS managed services instead of self-hosted containers
- **Rationale**: Reduced operational overhead, better security, automatic scaling
- **Services Used**:
  - ElastiCache Redis (instead of Redis container)
  - Amazon MQ RabbitMQ (instead of RabbitMQ container)
  - OpenSearch (instead of Elasticsearch container)
  - S3 (instead of MinIO container)
  - EFS (instead of RDS database)

#### **2. Serverless Architecture**
- **Decision**: ECS Fargate for all compute resources
- **Benefits**: No EC2 management, automatic scaling, pay-per-use
- **Cost Impact**: Significant reduction in operational costs

#### **3. Modular Terraform Design**
- **Decision**: Four separate modules (networking, storage, compute, services)
- **Benefits**: Better maintainability, reusability, separation of concerns

### ⚠️ **Challenges Encountered**

#### **1. OpenCTI Docker Image Compatibility**
- **Issue**: OpenCTI container failing to start with "Cannot find module" errors
- **Root Cause**: Missing environment variables and incorrect startup configuration
- **Solution**: 
  - Added proper environment variables
  - Configured correct health check paths
  - Used hardcoded UUID for admin token

#### **2. Service Discovery vs Direct Endpoints**
- **Issue**: Initially used Cloud Map for all services, then switched to direct endpoints
- **Challenge**: Balancing service discovery benefits with managed service simplicity
- **Solution**: Hybrid approach - Cloud Map for OpenCTI, direct endpoints for managed services

#### **3. SSL/TLS Configuration**
- **Issue**: RabbitMQ and OpenSearch require SSL connections
- **Challenge**: Configuring proper SSL settings for managed services
- **Solution**: 
  - RabbitMQ: SSL enabled, ports 5671/15671
  - OpenSearch: HTTPS endpoint with proper security groups

## Technical Challenges & Solutions

### **1. Environment Variable Configuration**

#### **Challenge**: OpenCTI requires specific environment variable format
```yaml
# Required format for OpenCTI
APP__ADMIN__EMAIL: "admin@opencti.io"
APP__ADMIN__PASSWORD: "changeme"
APP__ADMIN__TOKEN: "550e8400-e29b-41d4-a716-446655440000"
```

#### **Solution**: Comprehensive environment variable mapping
- Admin configuration with proper token format
- Service endpoint configuration for managed services
- SSL/TLS settings for secure connections

### **2. Health Check Configuration**

#### **Challenge**: Multi-layered health checks in Fargate environment
```yaml
# Container-level health check
healthCheck:
  command: ["CMD-SHELL", "curl -f http://localhost:8080/health || exit 1"]
  interval: 30
  timeout: 10
  retries: 5
  startPeriod: 180

# ALB health check
target_group:
  health_check_path: "/health"
  health_check_port: 8080
```

#### **Solution**: Proper health check hierarchy
- Container health checks for ECS
- ALB health checks for load balancer
- Managed service health checks (automatic)

### **3. IAM Role Configuration**

#### **Challenge**: S3 access without access keys
```hcl
# ECS Task Role with S3 permissions
resource "aws_iam_role" "ecs_task_role" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}
```

#### **Solution**: IAM role-based access
- ECS task role with S3 permissions
- S3 bucket policy allowing ECS task role access
- No access keys required

## Security Considerations

### **1. Network Security**
- **Private Subnets**: All application services in private subnets
- **Security Groups**: Least privilege access between services
- **ALB**: Single entry point for external access

### **2. Data Encryption**
- **At Rest**: All storage services encrypted (EFS, S3, ElastiCache, OpenSearch)
- **In Transit**: SSL/TLS for RabbitMQ and OpenSearch
- **Keys**: AWS managed keys for simplicity

### **3. Access Control**
- **IAM Roles**: Service-to-service authentication
- **No Access Keys**: Eliminates key management overhead
- **VPC Endpoints**: Secure communication with AWS services

## Cost Optimization Strategies

### **1. Instance Sizing**
```yaml
# Cost-optimized instance types
ElastiCache Redis: cache.t3.micro
Amazon MQ RabbitMQ: mq.t3.micro
OpenSearch: t3.small.search
ECS Fargate: 0.5 vCPU, 1GB RAM (OpenCTI)
```

### **2. Storage Optimization**
- **EFS**: Provisioned throughput (100 MiB/s)
- **S3**: Standard storage class
- **OpenSearch**: 20GB EBS volume

### **3. Log Retention**
- **CloudWatch Logs**: 7-day retention
- **Container Insights**: Enabled for monitoring

## Operational Considerations

### **1. Monitoring & Logging**
- **CloudWatch Logs**: Centralized logging for all services
- **ECS Container Insights**: Performance monitoring
- **Health Checks**: Multi-layered health monitoring

### **2. Deployment Strategy**
- **Blue/Green**: ECS service updates with zero downtime
- **Rolling Updates**: Gradual container replacement
- **Health Check Validation**: Ensures service availability

### **3. Backup & Recovery**
- **EFS**: Automatic backups (AWS managed)
- **S3**: Versioning enabled
- **OpenSearch**: Automated snapshots

## Lessons Learned

### **1. OpenCTI-Specific Considerations**
- **Admin Token**: Must be valid UUID format
- **Environment Variables**: Specific naming convention required
- **Health Checks**: Use `/health` endpoint, not root path
- **Startup Time**: Allow 180+ seconds for initial startup

### **2. AWS Managed Services**
- **Service-Linked Roles**: Required for OpenSearch VPC access
- **Parameter Groups**: Use correct family versions (redis7.x)
- **SSL Configuration**: Managed services often require SSL
- **Endpoint Format**: Different services use different endpoint formats

### **3. Terraform Best Practices**
- **Module Dependencies**: Careful ordering of resource creation
- **Output Dependencies**: Avoid circular dependencies
- **State Management**: Proper state file handling
- **Variable Validation**: Input validation for critical parameters

## Recommendations for Production

### **1. High Availability**
- **Multi-AZ**: Deploy across multiple availability zones
- **Auto Scaling**: Configure ECS service auto scaling
- **Load Balancing**: Multiple ALB instances

### **2. Security Hardening**
- **WAF**: Web Application Firewall for ALB
- **Secrets Manager**: Store sensitive configuration
- **VPC Flow Logs**: Network traffic monitoring

### **3. Monitoring & Alerting**
- **CloudWatch Alarms**: Proactive monitoring
- **SNS Notifications**: Alert on critical events
- **Custom Metrics**: Application-specific monitoring

### **4. Backup Strategy**
- **Cross-Region**: Backup to secondary region
- **Point-in-Time**: Regular backup schedules
- **Disaster Recovery**: Tested recovery procedures

## Cost Analysis

### **Estimated Monthly Costs (Demo Environment)**
```yaml
ElastiCache Redis (cache.t3.micro): ~$15/month
Amazon MQ RabbitMQ (mq.t3.micro): ~$20/month
OpenSearch (t3.small.search): ~$25/month
ECS Fargate (0.5 vCPU, 1GB): ~$10/month
ALB: ~$20/month
EFS (100 MiB/s): ~$30/month
S3 (minimal usage): ~$5/month
Total: ~$125/month
```

### **Production Scaling Costs**
```yaml
High Availability (Multi-AZ): 2x cost
Larger Instances: 3-5x cost
Additional Storage: Variable
Total Production: ~$500-1000/month
```

## Conclusion

The OpenCTI AWS deployment successfully demonstrates a modern, serverless architecture using AWS managed services. Key success factors include:

1. **Proper Environment Configuration**: Critical for OpenCTI startup
2. **Managed Services**: Reduced operational overhead
3. **Security-First Design**: Encrypted storage and network isolation
4. **Cost Optimization**: Appropriate instance sizing for demo environment
5. **Modular Architecture**: Maintainable and scalable design

The deployment provides a solid foundation for both demo and production environments, with clear paths for scaling and hardening as needed.
