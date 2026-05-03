# OctaByte DevOps Assignment

End-to-end DevOps implementation for a static web application on AWS, covering infrastructure provisioning, CI/CD automation, monitoring, and security best practices.

---

## Architecture Overview

```
GitHub → Jenkins CI/CD → S3 + CloudFront (Static App)
                      → DockerHub (Container Registry)

Terraform → VPC → Public Subnets  (EC2 App Server)
                → Private Subnets (RDS PostgreSQL)

CloudWatch Agent → Metrics + Logs → CloudWatch Dashboards
AWS Secrets Manager → DB Credentials
```

---

## Project Structure

```
octa-byte-ai-assessment/
├── app/                        # Static web application files
├── terraform/
│   ├── main.tf                 # Root module — calls all child modules
│   ├── variables.tf            # Configurable parameters with defaults
│   ├── outputs.tf              # Key resource outputs (URLs, IDs)
│   ├── providers.tf            # AWS provider config and S3 backend
│   └── modules/
│       ├── networking/         # VPC, subnets, IGW, route tables, security groups
│       ├── storage/            # S3 bucket, CloudFront distribution, OAC
│       └── database/           # RDS PostgreSQL, DB subnet group
├── Jenkinsfile                 # Declarative CI/CD pipeline
├── Dockerfile                  # Nginx-based container for static app
├── CHALLENGES.md               # Challenges faced and resolutions
└── README.md                   # This file
```

---

## Part 1: Infrastructure Provisioning

### Prerequisites

- Terraform >= 1.3.0
- AWS CLI installed and configured
- IAM user/role with permissions for EC2, S3, RDS, CloudFront

### Resources Provisioned

| Resource | Details |
|---|---|
| VPC | CIDR `10.0.0.0/24`, DNS enabled |
| Public Subnets | `10.0.0.0/26` and `10.0.0.64/26` across 2 AZs |
| Private Subnets | `10.0.0.128/26` and `10.0.0.192/26` for RDS |
| Internet Gateway | Attached to VPC for public subnet routing |
| S3 Bucket | Private bucket for static site files |
| CloudFront | CDN distribution with OAC, HTTPS enforced |
| RDS PostgreSQL | Version 16.6, db.t3.micro, private subnet |
| EC2 Instance | Referenced via Terraform data source |
| Security Groups | RDS restricted to VPC CIDR only |

### Setup and Run

```bash
# 1. Clone the repository
git clone https://github.com/siddardha-code/octa-byte-ai-assessment.git
cd devops-assignment

# 2. Create S3 bucket for Terraform remote state
aws s3api create-bucket \
  --bucket 8byte-devops-tfstate \
  --region ap-south-1 \
  --create-bucket-configuration LocationConstraint=ap-south-1

aws s3api put-bucket-versioning \
  --bucket 8byte-devops-tfstate \
  --versioning-configuration Status=Enabled

# 3. Initialize Terraform
cd terraform
terraform init

# 4. Preview changes
terraform plan -var="db_username=adminuser" -var="db_password=yourpassword"

# 5. Apply infrastructure
terraform apply -var="db_username=adminuser" -var="db_password=yourpassword"
```

### Outputs After Apply

```
cloudfront_url             = "d3j7syya0tc8gs.cloudfront.net"
s3_bucket_name             = "octa-byte-devops-static-site-staging"
cloudfront_distribution_id = "E3AVYPAHS4L4AO"
db_endpoint                = <sensitive>
```

### Architecture Decisions

**S3 + CloudFront instead of EC2 for static hosting**
The application is a static site. Serving it via S3 + CloudFront is the correct AWS-native pattern — globally distributed, automatically scaled, no server maintenance, and significantly cheaper than running a web server on EC2. EC2 is provisioned and referenced via Terraform data source for backend workloads if needed in future.

**VPC CIDR /24 with /26 subnets**
A /24 VPC provides 256 IPs which is sufficient for this workload. Four /26 subnets (64 IPs each) fit cleanly within the VPC — 2 public for application tier, 2 private for database tier, each across separate availability zones for fault tolerance.

**RDS in private subnets**
RDS has `publicly_accessible = false` and lives in private subnets with no internet route. Only resources within the VPC CIDR `10.0.0.0/24` can reach port 5432. This follows the principle of least privilege for database access.

**S3 backend for Terraform state**
State is stored in S3 with versioning enabled. This ensures state is not lost, is recoverable to any previous version, and is accessible from any machine — essential for team environments and disaster recovery.

**OAC instead of OAI for CloudFront**
Origin Access Control (OAC) is the modern AWS-recommended approach for securing S3 origins behind CloudFront. It uses SigV4 signing on every request, replacing the legacy Origin Access Identity (OAI) method.

---

## Part 2: CI/CD Pipeline (Jenkins)

### Pipeline Stages

| Stage | Trigger | Action |
|---|---|---|
| Checkout | Every push | Pull latest code from GitHub |
| Test | Every push | HTML validation using tidy linter |
| Build | Every push | Build Docker image tagged with build number + commit hash |
| Push | Every push | Push image to DockerHub (latest + versioned tag) |
| Deploy Staging | Merge to main | S3 sync + CloudFront cache invalidation |
| Approval | After staging | Manual gate — sends email notification, waits 24hrs |
| Deploy Production | After approval | S3 sync + CloudFront cache invalidation |
| Notify | On failure/success | Email via Extended Email Plugin |

### Jenkins Setup

```
1. Install Jenkins on EC2
2. Install plugins:
   - Pipeline
   - Git
   - GitHub Integration
   - Docker Pipeline
   - Email Extension Plugin

3. Configure credentials:
   - DockerHub: username/password stored in Jenkins credential store
   - AWS: handled via EC2 IAM instance role (no keys needed)

4. Configure email:
   - SMTP: smtp.gmail.com:465
   - Use Gmail App Password

5. Add GitHub webhook:
   - URL: http://your-ec2-ip:8080/github-webhook/
   - Events: push, pull_request

6. Create Pipeline job pointing to this repository
```

### Security Decision — No IAM Access Keys
Jenkins authenticates to AWS using the EC2 IAM instance role instead of long-lived IAM access keys. This eliminates credential rotation overhead, removes the risk of key leakage, and follows AWS security best practices. The pipeline uses the AWS credential provider chain automatically.

---

## Part 3: Monitoring and Logging

### Infrastructure Metrics (CloudWatch Agent)

| Metric | Source | Collection Interval |
|---|---|---|
| CPU usage (user, system) | EC2 | 60 seconds |
| Memory used percent | EC2 | 60 seconds |
| Disk used percent | EC2 | 60 seconds |
| Network bytes sent/received | EC2 | 60 seconds |
| CPU utilization | RDS | 60 seconds |
| Database connections | RDS | 60 seconds |
| Free storage space | RDS | 60 seconds |
| Read/Write latency | RDS | 60 seconds |

### Application Metrics (CloudFront)

| Metric | Namespace |
|---|---|
| Request rate | AWS/CloudFront |
| 4xx error rate | AWS/CloudFront |
| 5xx error rate | AWS/CloudFront |

### Centralized Log Groups

| Log Group | Source File |
|---|---|
| `/octabyte/devops/system-logs` | `/var/log/syslog` |
| `/octabyte/devops/jenkins-logs` | `/var/log/jenkins/jenkins.log` |
| `/octabyte/devops/access-logs` | `/var/log/auth.log` |

### Dashboards

**OctaByte-Infrastructure**
EC2 CPU, memory, disk usage + RDS CPU utilization, free storage, database connections

**OctaByte-Application**
CloudFront request rate, error rates + RDS read/write latency, IOPS, EC2 network traffic

### CloudWatch Agent Setup

```bash
# Download and install
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
sudo dpkg -i amazon-cloudwatch-agent.deb

# Start with config
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -s \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/cloudwatch-agent-config.json
```

---

## Part 4: Security and Best Practices

### Secret Management

Database credentials are stored in AWS Secrets Manager. Credentials are never hardcoded in Terraform files, pipeline scripts, or environment variables.

```bash
# Store credentials
aws secretsmanager create-secret \
    --name "octa-byte/devops/db-credentials" \
    --secret-string '{"username":"adminuser","password":"yourpassword"}' \
    --region ap-south-1

# Retrieve credentials
aws secretsmanager get-secret-value \
    --secret-id octa-byte/devops/db-credentials \
    --region ap-south-1
```

### Backup Strategy

RDS automated backups are configured:

| Setting | Value |
|---|---|
| Retention period | 7 days |
| Backup window | 03:00 - 04:00 UTC daily |
| Storage encrypted | Yes (AES-256) |
| Recovery | AWS Console → RDS → Automated Backups |

### Security Considerations

| Area | Implementation |
|---|---|
| RDS access | No public IP, private subnet only, port 5432 restricted to VPC CIDR |
| S3 access | All public access blocked, served only via CloudFront OAC |
| HTTPS | CloudFront enforces redirect-to-https on all requests |
| SSH access | EC2 security group restricts SSH to specific IP |
| AWS auth | IAM instance roles used instead of access keys |
| Terraform state | Encrypted at rest in S3, versioning enabled |
| Secrets | All credentials in AWS Secrets Manager, never in code |

### Cost Optimization

| Decision | Saving |
|---|---|
| S3 + CloudFront for static site | Eliminates EC2 compute cost for serving |
| RDS db.t3.micro | Smallest instance sufficient for this workload |
| CloudFront free tier | Covers 1TB transfer + 10M requests/month |
| No NAT Gateway | Private subnets don't need internet access |
| Pay-per-request on DynamoDB | Zero cost for low-frequency state locking |

---

## Live Environment

| Resource | URL / ID |
|---|---|
| Application URL | https://d3j7syya0tc8gs.cloudfront.net |
| CloudFront Distribution | E3AVYPAHS4L4AO |
| S3 Bucket | octa-byte-devops-static-site-staging |
| RDS Identifier | octa-byte-devops-postgres |
| Jenkins | http://ec2-ip:8080 |

---

## Destroying Infrastructure

To avoid ongoing charges after the assignment:

```bash
cd terraform

# Destroy only RDS first (most expensive)
terraform destroy -target=module.database \
  -var="db_username=adminuser" \
  -var="db_password=yourpassword"

# Destroy everything else
terraform destroy \
  -var="db_username=adminuser" \
  -var="db_password=yourpassword"
```
