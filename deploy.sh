#!/bin/bash

set -e

echo "🔐 Step 1: Creating SSM parameters (secrets and configuration)..."
terraform apply -target=aws_ssm_parameter.rds_master_username \
                -target=aws_ssm_parameter.rds_master_password \
                -target=aws_ssm_parameter.admin_secret \
                -target=aws_ssm_parameter.db_url \
                -target=aws_ssm_parameter.domain_name \
                -target=aws_ssm_parameter.rds_db_endpoint \
                -auto-approve

echo "✅ SSM parameters created successfully."

echo "🚀 Step 2: Deploying full infrastructure..."
terraform apply -auto-approve

echo "🎉 Done! Infrastructure deployed successfully."
