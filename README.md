# 🚀 AWS Hasura GraphQL Dev Environment Deployment

## 🌟 Overview

This repository provides a comprehensive Infrastructure as Code (IaC) solution using Terraform to deploy a lightweight, isolated development environment for Hasura GraphQL Engine on AWS.

Key features:

- 🐳 Hasura on **Amazon ECS Fargate**
- 🛢️ PostgreSQL-compatible **Amazon Aurora** in RDS
- 🔐 Secure secrets in **AWS Systems Manager Parameter Store**
- 🌍 Public & private access via **Route 53**
- 👥 Support for isolated developer environments (sub-accounts)
- 💸 Optimized for **low-cost, low-resource** dev setups

---

## ✨ Features

- **Cloud-Native IaC** – Clean separation of concerns with Terraform modules.
- **Serverless Hasura** – No EC2 maintenance needed.
- **PostgreSQL DB with Schemas** – Organized and scalable DB structure.
- **Secrets Management** – Secure injection via SSM into ECS.
- **Flexible Access** – ALB + Route 53 for both public and private endpoints.
- **Developer Isolation** – Easily replicate isolated dev environments.
- **Minimal Resource Footprint** – Ideal for dev/test environments.

---

## 📋 Prerequisites

Ensure the following are installed and configured:

- ✅ AWS account + IAM user with `AdministratorAccess`
- ✅ [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
- ✅ [Terraform](https://www.terraform.io/downloads.html) (v1.0+)
