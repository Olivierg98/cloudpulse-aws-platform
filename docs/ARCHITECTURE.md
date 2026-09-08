# Architecture

```mermaid
flowchart TB
  User[Internet user] --> ALB[Application Load Balancer]
  ALB --> A[EC2 / AZ-a]
  ALB --> B[EC2 / AZ-b]
  ASG[Auto Scaling Group] --> A
  ASG --> B
  A --> CW[CloudWatch]
  B --> CW
  SSM[Systems Manager] --> A
  SSM --> B
```

The ALB is the only public entry point. Application security groups accept port 8000 only from the ALB. Instances require IMDSv2 and use Systems Manager instead of inbound SSH. An Auto Scaling Group replaces unhealthy capacity and distributes it across two availability zones.
