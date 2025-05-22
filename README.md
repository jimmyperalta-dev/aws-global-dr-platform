# 🌍 AWS Global Disaster Recovery Platform

![AWS Cloud](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)
![Work in Progress](https://img.shields.io/badge/Status-Work%20in%20Progress-yellow?style=for-the-badge&logo=github&logoColor=white)
![Multi Region](https://img.shields.io/badge/Multi--Region-Active-green?style=for-the-badge&logo=amazon-aws&logoColor=white)

🔗 **Status:** Infrastructure deployment in progress - showcasing enterprise-level disaster recovery architecture

## 📋 Project Overview

This project implements an enterprise-grade AWS Global Disaster Recovery Platform using Infrastructure as Code (Terraform). The solution demonstrates all five AWS Well-Architected Framework pillars through a realistic multi-region disaster recovery scenario with automated failover capabilities.

**Primary Region:** us-east-1 (N. Virginia)  
**DR Region:** us-west-2 (Oregon)

---

## ✅ Key Features & Services

- 🏗️ **Infrastructure as Code** - Complete AWS infrastructure defined in Terraform
- 🌍 **Multi-Region Architecture** - Primary and disaster recovery regions
- 🔄 **Automated Failover** - Route 53 health checks with DNS failover
- 🗄️ **Database Replication** - RDS cross-region read replicas
- 📦 **Storage Replication** - S3 cross-region replication
- ⚖️ **Load Balancing** - Application Load Balancers in both regions
- 🔧 **Auto Scaling** - Dynamic scaling based on demand
- 📊 **Monitoring** - CloudWatch dashboards and alarms

---

## 📁 Project Structure

```
aws-global-dr-platform/
├── terraform/                    # Infrastructure as Code
│   ├── environments/
│   │   ├── primary/             # us-east-1 configuration
│   │   └── dr/                  # us-west-2 configuration
│   └── modules/                 # Reusable Terraform modules
│       ├── networking/
│       ├── compute/
│       ├── database/
│       └── storage/
├── architecture/                # Architecture diagrams
├── docs/                       # Additional documentation
├── scripts/                    # Deployment scripts
└── README.md
```

---

## 🚀 Deployment Status

- [x] Project structure initialization
- [ ] Networking infrastructure (VPC, Subnets, Gateways)
- [ ] Compute infrastructure (ASG, ALB, EC2)
- [ ] Database setup (RDS Multi-AZ, Cross-region replicas)
- [ ] Storage configuration (S3 cross-region replication)
- [ ] DNS and failover (Route 53 health checks)
- [ ] Monitoring and alerting (CloudWatch)

---

## 👤 Author

**Jimmy Peralta**  
🛠️ Associate Media Systems Engineer | ☁️ AWS Cloud Enthusiast  
🌐 [https://www.deployjimmy.com](https://www.deployjimmy.com)
