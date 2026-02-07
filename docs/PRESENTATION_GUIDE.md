# Wiz Technical Exercise - Presentation Guide

## 45-Minute Presentation Structure

### Slide Deck Overview

This guide provides a recommended slide structure for the Wiz Technical Exercise presentation.

---

## SLIDE 1: Title Slide
**Title:** Wiz Technical Exercise - Cloud Native Application Security
**Subtitle:** Two-Tier Web Application with Intentional Misconfigurations
**Your Name**
**Date**

---

## SLIDE 2: Agenda
1. Overview & Objectives
2. Architecture Walkthrough
3. DevOps Implementation
4. Security Controls
5. Intentional Misconfigurations & Detection
6. Live Demo
7. Lessons Learned & Q&A

**Time: 1 minute**

---

## SLIDE 3: Exercise Objectives
**What Was Built:**
- Two-tier web application (Express + MongoDB)
- Deployed on AWS (EKS + EC2)
- Infrastructure as Code (Terraform)
- CI/CD pipelines (GitHub Actions)
- Comprehensive security controls
- Intentional misconfigurations for CNAPP testing

**Technologies:**
- AWS (EKS, EC2, VPC, S3, IAM)
- Kubernetes, Docker
- Terraform, GitHub Actions
- Security: GuardDuty, Security Hub, Inspector, WAF

**Time: 2 minutes**

---

## SLIDE 4: High-Level Architecture
**Visual:** Show the high-level architecture diagram from EXERCISE_GUIDE.md

**Key Components:**
- VPC with public and private subnets
- EKS cluster (private subnets)
- MongoDB EC2 (public subnet - intentionally misconfigured)
- S3 bucket for backups (public read - intentionally misconfigured)
- AWS security services (GuardDuty, Security Hub, etc.)

**Time: 3 minutes**

---

## SLIDE 5: Network Architecture
**Visual:** Show network topology diagram

**Discuss:**
- Multi-AZ deployment for HA
- Public subnets: ALB, MongoDB VM
- Private subnets: EKS nodes
- NAT Gateway for outbound connectivity
- Security groups and network segmentation

**Highlight Misconfigurations:**
- 🔴 MongoDB in public subnet with public IP
- 🔴 SSH exposed to 0.0.0.0/0

**Time: 3 minutes**

---

## SLIDE 6: Application Stack
**Frontend/Backend:**
- Node.js Express application
- Containerized with Docker
- Deployed to EKS
- NGINX Ingress Controller
- Application Load Balancer

**Database:**
- MongoDB 4.4 (intentionally outdated)
- Running on Debian 10 (intentionally outdated)
- Accessible from VPC CIDR only (port 27017)
- Daily backups to S3

**Time: 2 minutes**

---

## SLIDE 7: Infrastructure as Code
**Terraform Structure:**
```
terraform/
├── main.tf          # Core resources, security services
├── vpc.tf           # VPC, subnets, networking
├── eks.tf           # EKS cluster
├── mongo-vm/        # MongoDB EC2 module
└── variables.tf     # Configuration
```

**Resources Provisioned:**
- VPC with 2 AZs, 4 subnets
- EKS cluster with managed node groups
- EC2 instance for MongoDB
- S3 buckets (backups, logs)
- Security services (GuardDuty, Security Hub, Inspector, Config, CloudTrail)
- WAF with managed rule sets
- IAM roles and security groups

**Time: 3 minutes**

---

## SLIDE 8: CI/CD Pipeline - Infrastructure
**Workflow:** `.github/workflows/infra-ci.yml`

**Pipeline Steps:**
1. Terraform Format Check
2. Terraform Init
3. Terraform Validate
4. **Checkov Security Scan** (IaC misconfigurations)
5. Yor Tagging (resource traceability)
6. Upload SARIF to GitHub Security

**Benefits:**
- Infrastructure validated before deployment
- Security issues caught early
- Audit trail via Git history
- Reproducible infrastructure

**Time: 2 minutes**

---

## SLIDE 9: CI/CD Pipeline - Application
**Workflow:** `.github/workflows/app-deploy.yml`

**Pipeline Steps:**
1. Authenticate to AWS (OIDC)
2. Build Docker image
3. **Trivy Vulnerability Scan**
4. Push to Amazon ECR
5. Update EKS deployment
6. Wait for rollout completion

**Security Integration:**
- Container vulnerability scanning
- Automated deployment to K8s
- Health checks and gradual rollout

**Time: 2 minutes**

---

## SLIDE 10: Detective Security Controls
**AWS Services Implemented:**

| Service | Purpose | Integration |
|---------|---------|-------------|
| **GuardDuty** | Threat detection (VPC Flow, CloudTrail, DNS) | → Security Hub |
| **Security Hub** | Centralized findings (CIS, AWS Foundational) | SNS alerts |
| **Inspector** | Vulnerability scanning (EC2, ECR) | → Security Hub |
| **CloudTrail** | API audit logging (multi-region) | → Security Hub |
| **AWS Config** | Configuration tracking | → Security Hub |
| **Detective** | Security investigation | GuardDuty data |
| **VPC Flow Logs** | Network monitoring | CloudWatch |

**Result:** Comprehensive visibility into security posture

**Time: 3 minutes**

---

## SLIDE 11: Preventive Security Controls
**Controls Implemented:**

**AWS WAF:**
- OWASP Top 10 protection
- Known bad inputs filter
- SQL injection protection
- Rate limiting (2000 req/5min)

**Security Groups:**
- MongoDB: VPC CIDR only (port 27017)
- ALB: Internet access (80, 443)
- EKS: Internal cluster traffic

**IAM:**
- Least privilege (mostly)
- Instance profiles for EC2
- EKS node roles
- Service account roles

**Time: 2 minutes**

---

## SLIDE 12: CI/CD Security Scanning
**Tools Integrated:**

**Checkov** (IaC Scanning):
- 750+ policies
- Detects misconfigurations before deployment
- SARIF output to GitHub Security

**Trivy** (Container Scanning):
- OS package vulnerabilities
- Application dependency scanning
- Weekly scheduled scans

**GitHub Security:**
- Centralized security findings
- Dependabot for dependency updates
- Secret scanning

**Time: 2 minutes**

---

## SLIDE 13: Intentional Misconfigurations - Critical
**🔴 Critical Severity**

### 1. Public S3 Bucket
- **Issue:** MongoDB backups publicly readable
- **Risk:** Data breach, compliance violation
- **Location:** `terraform/main.tf` - S3 bucket policy
- **Detection:** Security Hub, AWS Config
- **CVSS:** 9.1 | **CWE:** 284 | **ATT&CK:** T1530

### 2. Cluster-Admin Pod Role
- **Issue:** Application pod has full cluster control
- **Risk:** Container escape, cluster takeover
- **Location:** `app/rbac.yaml`
- **Detection:** Manual review, RBAC auditing
- **CVSS:** 9.9 | **CWE:** 250 | **ATT&CK:** T1611

**Time: 3 minutes**

---

## SLIDE 14: Intentional Misconfigurations - High
**🟠 High Severity**

### 1. SSH Exposed to Internet
- **Issue:** Port 22 open to 0.0.0.0/0
- **Risk:** Brute force attacks
- **CVSS:** 7.5

### 2. Outdated OS (Debian 10)
- **Issue:** 1+ year old, unpatched CVEs
- **Risk:** Exploitation for privilege escalation
- **CVSS:** 7.8

### 3. Outdated MongoDB (4.4)
- **Issue:** Released 2020, known vulnerabilities
- **Risk:** Database compromise
- **CVSS:** 8.1

### 4. Overly Permissive IAM
- **Issue:** EC2 can create instances
- **Risk:** Lateral movement, resource abuse
- **CVSS:** 7.2

**Time: 3 minutes**

---

## SLIDE 15: Security Findings Summary
**Visual:** Pie chart or table

| Severity | Count | Examples |
|----------|-------|----------|
| **Critical** | 2 | Public S3, Cluster-admin RBAC |
| **High** | 4 | SSH exposed, outdated OS/DB, permissive IAM |
| **Medium** | 2 | No network policies, no resource limits |
| **Low** | 3 | No API auth, public subnet placement |

**Total Risk Score:** HIGH

**Time: 2 minutes**

---

## SLIDE 16: Detection Capabilities
**How Misconfigurations Are Detected:**

| Misconfiguration | Detection Method |
|------------------|------------------|
| Public S3 | Security Hub, AWS Config |
| Cluster-admin RBAC | K8s audit logs, manual review |
| SSH exposure | Security Hub, VPC Flow Logs |
| Outdated software | Inspector, Security Hub |
| Permissive IAM | Security Hub, AWS Config |

**Continuous Monitoring:**
- GuardDuty: Real-time threat detection
- Security Hub: Compliance scoring
- Inspector: Vulnerability updates
- CloudTrail: API audit trail

**Time: 2 minutes**

---

## SLIDE 17: Live Demo Preview
**What You'll See:**

1. **Application Demo**
   - Access via load balancer
   - Show MongoDB connectivity
   - Display data from database

2. **Kubernetes Demo**
   - kubectl commands
   - Verify wizexercise.txt in container
   - Demonstrate cluster-admin access (security risk)

3. **Security Services Demo**
   - Security Hub dashboard
   - GuardDuty findings
   - Inspector vulnerabilities
   - WAF metrics

4. **CI/CD Demo**
   - GitHub Actions workflows
   - Security scan results
   - SARIF integration

**Time: 1 minute**

---

## SLIDE 18: Methodology & Approach
**Design Decisions:**

**Why AWS?**
- Mature security services
- Comprehensive detective controls
- Integration with CI/CD

**Why EKS?**
- Production-grade orchestration
- Managed control plane
- AWS service integration

**Why Terraform?**
- Infrastructure as Code
- Version control
- Reproducibility

**Why GitHub Actions?**
- Native CI/CD
- OIDC authentication
- Security scanning integration

**Time: 2 minutes**

---

## SLIDE 19: Challenges Faced
**Key Challenges & Solutions:**

1. **Challenge:** Balancing security with intentional misconfigurations
   **Solution:** Clear documentation, isolated from production patterns

2. **Challenge:** MongoDB access from private EKS nodes
   **Solution:** Security group rules for VPC CIDR, tested connectivity

3. **Challenge:** OIDC authentication for GitHub Actions
   **Solution:** AWS IAM OIDC provider configuration

4. **Challenge:** WAF rule tuning
   **Solution:** Count mode for observation, metrics for optimization

5. **Challenge:** Terraform state management
   **Solution:** Terraform Cloud for remote state, team collaboration

**Time: 2 minutes**

---

## SLIDE 20: Production Improvements
**What Would I Add for Production?**

**High Priority:**
- ✅ Move MongoDB to private subnet
- ✅ Restrict SSH to VPN/bastion
- ✅ Update all software to latest versions
- ✅ Remove public S3 access
- ✅ Apply least privilege RBAC

**Additional Enhancements:**
- Multi-region deployment
- Database replication & automated failover
- Secrets Manager for credentials
- KMS encryption for all data
- Pod Security Standards enforcement
- Network policies for pod isolation
- Auto-scaling policies
- Enhanced monitoring & alerting

**Time: 2 minutes**

---

## SLIDE 21: Real-World Relevance
**These Aren't Just Theoretical:**

**Common Real-World Scenarios:**
- **Public S3 buckets:** Major breaches (Capital One, Accenture)
- **SSH exposure:** Cryptocurrency mining, ransomware
- **Outdated software:** Log4Shell, Heartbleed
- **Overly permissive IAM:** Privilege escalation attacks
- **Cluster-admin pods:** Container escape attacks

**Lessons:**
- Security misconfigurations are #1 cloud risk
- Defense in depth is essential
- Detective AND preventive controls needed
- Automation prevents drift
- Continuous monitoring catches anomalies

**Time: 2 minutes**

---

## SLIDE 22: Value of CNAPP Solutions
**What Problems Do CNAPP Platforms Solve?**

**Visibility:**
- Unified view across cloud resources
- Real-time misconfiguration detection
- Comprehensive asset inventory

**Prevention:**
- IaC scanning before deployment
- Policy enforcement
- Guardrails for developers

**Detection:**
- Runtime threat detection
- Anomaly identification
- Attack path analysis

**Response:**
- Prioritized findings by risk
- Automated remediation
- Incident investigation tools

**This Exercise Demonstrates:** Why organizations need CNAPP

**Time: 2 minutes**

---

## SLIDE 23: Thank You & Questions
**Summary:**
- Built two-tier web application with intentional misconfigurations
- Implemented comprehensive DevOps automation
- Deployed detective and preventive security controls
- Demonstrated detection capabilities
- Ready for live demonstration

**Next Steps:**
- Live walkthrough
- Q&A discussion
- Wiz platform overview

**Contact Information:**
- GitHub: [repository link]
- Email: [your email]

**Time: 1 minute**

---

## Live Demo Checklist (15 minutes)

### Application Demo (3 minutes)
```bash
# Show application URL
echo "Application: http://[ALB-DNS]"

# Test endpoints
curl http://[ALB-DNS]/healthz
curl http://[ALB-DNS]/items

# Show in browser
# Demonstrate working application
```

### Kubernetes Demo (4 minutes)
```bash
# Cluster info
kubectl cluster-info
kubectl get nodes

# Show pods
kubectl get pods -n demo
kubectl get svc -n demo
kubectl get ingress -n demo

# Show RBAC misconfiguration
kubectl get clusterrolebinding express-hello-admin -o yaml

# Exec into pod
kubectl exec -it -n demo deploy/express-hello -- sh

# Inside pod - verify wizexercise.txt
cat /app/wizexercise.txt

# Inside pod - demonstrate security risk
kubectl get secrets --all-namespaces | head -10
# This works because of cluster-admin role!
```

### MongoDB Demo (2 minutes)
```bash
# Show MongoDB VM
aws ec2 describe-instances --filters "Name=tag:Name,Values=*mongo*"

# SSH to instance
ssh admin@[mongodb-ip]

# Show MongoDB version (outdated)
mongod --version

# Show S3 backup
aws s3 ls s3://[backup-bucket]/
```

### Security Services Demo (5 minutes)

**Security Hub:**
- Navigate to Security Hub dashboard
- Show compliance score
- Filter findings by severity
- Show specific misconfiguration findings

**GuardDuty:**
- Show GuardDuty findings
- Explain threat types
- Show integration with Security Hub

**Inspector:**
- Show EC2 vulnerability findings
- Show ECR image findings
- Filter by CVE severity

**WAF:**
- Show WAF dashboard
- Display rule metrics
- Show request counts and blocks

**CloudTrail:**
- Show recent API events
- Filter for specific actions
- Demonstrate audit capability

### CI/CD Demo (1 minute)
- Show GitHub Actions workflows
- Display security scan results
- Show SARIF integration in Security tab

---

## Talking Points for Q&A

### Technical Questions

**Q: Why not use managed MongoDB (DocumentDB)?**
A: Exercise requires intentional misconfigurations on VM (SSH exposure, outdated OS/DB, overly permissive IAM). Managed service doesn't allow this level of control.

**Q: How would you secure this for production?**
A: See slide 20 - move to private subnet, restrict SSH, update software, remove public S3, apply least privilege, add encryption, implement network policies.

**Q: What's your disaster recovery plan?**
A: Daily S3 backups (currently public - would be private in prod), multi-AZ deployment, would add multi-region replication, automated failover, tested restore procedures.

**Q: How do you handle secrets?**
A: Currently in K8s secrets (not ideal). Production would use AWS Secrets Manager, encrypted at rest with KMS, rotation policies, IAM-based access.

**Q: What's the network latency between EKS and MongoDB?**
A: Both in same VPC (10.0.0.0/16), different subnets. Low latency (<1ms). Would measure with application metrics in production.

### Architecture Questions

**Q: Why EKS vs. self-managed K8s?**
A: Managed control plane reduces operational overhead, automatic updates, AWS service integration, security features, high availability built-in.

**Q: Why not use multiple MongoDB instances for HA?**
A: Exercise focuses on security misconfigurations, not HA. Production would use replica sets or DocumentDB.

**Q: How do you handle scaling?**
A: EKS node auto-scaling configured, HPA for pods (would configure based on metrics), MongoDB would need replica set or managed service for horizontal scaling.

### Security Questions

**Q: What's your incident response plan?**
A: GuardDuty/Security Hub findings → SNS → On-call engineer. CloudTrail for forensics, Detective for investigation, automated isolation via Lambda functions (would implement).

**Q: How do you prevent container escape?**
A: Production would use Pod Security Standards, remove cluster-admin, apply securityContext, use read-only root filesystem, drop capabilities, non-root user.

**Q: What about supply chain security?**
A: Trivy scans for vulnerabilities, would add image signing (Notary/Cosign), SBOM generation, trusted registries only, admission controllers.

**Q: How do you handle compliance?**
A: Security Hub provides CIS and AWS Foundational compliance scores, would add: PCI-DSS, HIPAA, SOC2 depending on requirements, regular audits.

### DevOps Questions

**Q: How long does deployment take?**
A: Infrastructure (Terraform): ~20 minutes. Application (container): ~5 minutes. Total fresh deployment: ~25 minutes.

**Q: How do you handle rollbacks?**
A: K8s deployment history (kubectl rollout undo), immutable infrastructure (Terraform), container image tags, would add blue-green deployments.

**Q: What's your branching strategy?**
A: Main branch for production, feature branches for changes, PR reviews required, automated testing in CI, manual approval for production deployments.

---

## Presentation Tips

### Before the Presentation
- [ ] Test all demos in advance
- [ ] Have backup screenshots if live demo fails
- [ ] Know your architecture cold
- [ ] Practice within 45-minute time limit
- [ ] Prepare for common questions
- [ ] Have AWS console tabs pre-opened
- [ ] Have kubectl context set
- [ ] Test network connectivity

### During the Presentation
- **Be confident** - You built this!
- **Tell a story** - Journey from requirements to implementation
- **Highlight decisions** - Why you made specific choices
- **Show enthusiasm** - Demonstrate passion for security
- **Be honest** - Acknowledge limitations and improvements
- **Engage audience** - Ask if they have questions
- **Manage time** - Keep to schedule, can always go deeper in Q&A

### Handling Questions
- **Listen carefully** - Make sure you understand the question
- **Pause before answering** - Take a moment to think
- **Be honest** - Say "I don't know but here's how I'd find out"
- **Connect to experience** - Share relevant examples
- **Keep it concise** - Respect time constraints

### If Demo Fails
- **Stay calm** - Have screenshots ready
- **Explain what should happen** - Walk through expected results
- **Show logs/code instead** - Prove you know the system
- **Offer to show later** - If time allows

---

## Success Metrics

**You've succeeded if you can:**
- ✅ Explain the architecture clearly
- ✅ Demonstrate working application
- ✅ Show security misconfigurations
- ✅ Prove detection capabilities
- ✅ Discuss trade-offs and decisions
- ✅ Answer technical questions confidently
- ✅ Convey passion for security
- ✅ Connect to real-world scenarios

---

## Additional Resources

**Reference Documents:**
- `EXERCISE_GUIDE.md` - Complete implementation guide
- `DEPLOYMENT_README.md` - Deployment instructions
- `WELL_ARCHITECTED.md` - Architecture justification
- `docs/ARCHITECTURE_DIAGRAMS.md` - Visual diagrams

**Repository:**
- https://github.com/neuralhawk7/cnapp-exercise

**AWS Documentation:**
- [Security Hub](https://docs.aws.amazon.com/securityhub/)
- [GuardDuty](https://docs.aws.amazon.com/guardduty/)
- [Inspector](https://docs.aws.amazon.com/inspector/)

Good luck with your presentation! 🚀
