# OpenCTI AWS Deployment: Presentation Summary

## 🎯 **Project Overview**

**Objective**: Deploy OpenCTI (Open Cyber Threat Intelligence Platform) on AWS using serverless architecture with managed services.

**Approach**: Modern, cost-effective, secure deployment using ECS Fargate and AWS managed services.

---

## 🏗️ **Architecture Highlights**

### **Core Design Principles**
- ✅ **Serverless First**: ECS Fargate for all compute
- ✅ **Managed Services**: Redis, RabbitMQ, OpenSearch, S3, EFS
- ✅ **Security by Design**: Private subnets, encrypted storage, IAM roles
- ✅ **Cost Optimized**: Small instances, single AZ for demo

### **Infrastructure Stack**
```
Internet → ALB → ECS Fargate → AWS Managed Services
                ├── OpenCTI Platform
                ├── Worker Services (3x)
                └── Managed Services:
                    ├── ElastiCache Redis
                    ├── Amazon MQ RabbitMQ
                    ├── OpenSearch
                    ├── S3 Storage
                    └── EFS Filesystem
```

---

## ⚠️ **Key Challenges & Solutions**

### **1. OpenCTI Container Startup Issues**
- **Problem**: Container failing with "Cannot find module" errors
- **Root Cause**: Missing environment variables and incorrect configuration
- **Solution**: Comprehensive environment variable mapping and proper health checks

### **2. Service Discovery Complexity**
- **Problem**: Balancing Cloud Map vs direct endpoints
- **Solution**: Hybrid approach - Cloud Map for OpenCTI, direct endpoints for managed services

### **3. SSL/TLS Configuration**
- **Problem**: Managed services require SSL connections
- **Solution**: Proper SSL configuration for RabbitMQ (5671/15671) and OpenSearch (HTTPS)

### **4. IAM Role Configuration**
- **Problem**: S3 access without access keys
- **Solution**: ECS task role with S3 permissions and bucket policy

---

## 🔧 **Technical Solutions**

### **Environment Variables**
```yaml
# Critical OpenCTI configuration
APP__ADMIN__EMAIL: "admin@opencti.io"
APP__ADMIN__PASSWORD: "changeme"
APP__ADMIN__TOKEN: "550e8400-e29b-41d4-a716-446655440000"
NODE_ENV: "production"
```

### **Health Check Strategy**
```yaml
# Multi-layered health checks
Container Level: localhost:8080/health
ALB Level: /health endpoint
Managed Services: AWS automatic health checks
```

### **Security Configuration**
```yaml
# Network Security
- Private subnets for all services
- Security groups with least privilege
- ALB as single entry point

# Data Security
- Encryption at rest (EFS, S3, ElastiCache, OpenSearch)
- SSL/TLS in transit
- IAM role-based access
```

---

## 💰 **Cost Analysis**

### **Demo Environment (Monthly)**
| Service | Instance Type | Cost |
|---------|---------------|------|
| ElastiCache Redis | cache.t3.micro | ~$15 |
| Amazon MQ RabbitMQ | mq.t3.micro | ~$20 |
| OpenSearch | t3.small.search | ~$25 |
| ECS Fargate | 0.5 vCPU, 1GB | ~$10 |
| ALB | Standard | ~$20 |
| EFS | 100 MiB/s | ~$30 |
| S3 | Minimal usage | ~$5 |
| **Total** | | **~$125** |

### **Production Scaling**
- **High Availability**: 2x cost (~$250/month)
- **Larger Instances**: 3-5x cost (~$500-1000/month)

---

## 📊 **Key Metrics & Benefits**

### **Operational Benefits**
- ✅ **Zero EC2 Management**: Fully serverless
- ✅ **Automatic Scaling**: ECS Fargate auto-scaling
- ✅ **Managed Services**: Reduced operational overhead
- ✅ **Security**: Encrypted storage and network isolation

### **Development Benefits**
- ✅ **Modular Design**: Four separate Terraform modules
- ✅ **Reusable Components**: Easy to modify and extend
- ✅ **Infrastructure as Code**: Version controlled and repeatable

### **Business Benefits**
- ✅ **Cost Effective**: Pay only for what you use
- ✅ **Scalable**: Easy to scale up for production
- ✅ **Secure**: Enterprise-grade security features
- ✅ **Reliable**: AWS managed services with SLA

---

## 🚀 **Lessons Learned**

### **OpenCTI-Specific**
1. **Admin Token**: Must be valid UUID format
2. **Environment Variables**: Specific naming convention required
3. **Health Checks**: Use `/health` endpoint, not root path
4. **Startup Time**: Allow 180+ seconds for initial startup

### **AWS Managed Services**
1. **Service-Linked Roles**: Required for OpenSearch VPC access
2. **Parameter Groups**: Use correct family versions (redis7.x)
3. **SSL Configuration**: Managed services often require SSL
4. **Endpoint Format**: Different services use different formats

### **Terraform Best Practices**
1. **Module Dependencies**: Careful ordering of resource creation
2. **Output Dependencies**: Avoid circular dependencies
3. **State Management**: Proper state file handling
4. **Variable Validation**: Input validation for critical parameters

---

## 🎯 **Recommendations**

### **For Demo/Testing**
- ✅ Current configuration is optimal
- ✅ Cost-effective and functional
- ✅ Easy to deploy and manage

### **For Production**
- 🔄 **Multi-AZ Deployment**: High availability
- 🔄 **Auto Scaling**: ECS service auto scaling
- 🔄 **WAF**: Web Application Firewall
- 🔄 **Secrets Manager**: Sensitive configuration
- 🔄 **Cross-Region Backup**: Disaster recovery

### **For Scaling**
- 📈 **Larger Instances**: Based on load requirements
- 📈 **Additional Workers**: More background processing
- 📈 **Read Replicas**: For OpenSearch and Redis
- 📈 **CDN**: For static content delivery

---

## ✅ **Success Criteria Met**

- ✅ **Functional Deployment**: OpenCTI running successfully
- ✅ **Cost Optimized**: ~$125/month for demo environment
- ✅ **Secure Architecture**: Encrypted storage and network isolation
- ✅ **Scalable Design**: Easy to scale for production
- ✅ **Maintainable Code**: Modular Terraform structure
- ✅ **Documentation**: Comprehensive README and considerations

---

## 🔮 **Future Enhancements**

1. **Monitoring**: CloudWatch dashboards and alarms
2. **CI/CD**: Automated deployment pipeline
3. **Backup**: Automated backup and recovery procedures
4. **Security**: WAF, Secrets Manager, VPC Flow Logs
5. **Performance**: Caching layers and CDN integration

---

## 📝 **Conclusion**

The OpenCTI AWS deployment successfully demonstrates a modern, serverless architecture that is:

- **Cost-Effective**: Optimized for demo environments
- **Secure**: Enterprise-grade security features
- **Scalable**: Ready for production scaling
- **Maintainable**: Well-documented and modular design

This deployment provides a solid foundation for both demo and production environments, with clear paths for scaling and hardening as needed.
