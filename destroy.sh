#!/bin/bash

# Exit on any error
set -e

# Project/environment naming (обнови под свои значения)
PROJECT_NAME="hasura"
ENV="dev"
REGION="ap-southeast-1"

echo "🔻 Starting Terraform destroy..."
terraform destroy -auto-approve

echo "✅ Terraform destroy complete."
echo "🧹 Starting manual cleanup of AWS resources..."

# Delete Load Balancer
echo "⛔ Deleting Load Balancer..."
LB_ARN=$(aws elbv2 describe-load-balancers --region $REGION \
  --query "LoadBalancers[?contains(LoadBalancerName, '$PROJECT_NAME-$ENV-alb')].LoadBalancerArn" \
  --output text)

if [ -n "$LB_ARN" ]; then
  aws elbv2 delete-load-balancer --region $REGION --load-balancer-arn "$LB_ARN"
  echo "✔️ Load Balancer deleted: $LB_ARN"
else
  echo "ℹ️ No matching Load Balancer found."
fi

# Delete Target Group
echo "⛔ Deleting Target Group..."
TG_ARN=$(aws elbv2 describe-target-groups --region $REGION \
  --query "TargetGroups[?contains(TargetGroupName, '$PROJECT_NAME-$ENV-tg')].TargetGroupArn" \
  --output text)

if [ -n "$TG_ARN" ]; then
  aws elbv2 delete-target-group --region $REGION --target-group-arn "$TG_ARN"
  echo "✔️ Target Group deleted: $TG_ARN"
else
  echo "ℹ️ No matching Target Group found."
fi

# Delete RDS Cluster
echo "⛔ Deleting RDS Cluster..."
aws rds delete-db-cluster \
  --region $REGION \
  --db-cluster-identifier "$PROJECT_NAME-$ENV-aurora-pg" \
  --skip-final-snapshot || echo "⚠️ RDS Cluster not found or already deleted"

# Delete RDS Instances
for i in 0 1; do
  INSTANCE_ID="${PROJECT_NAME}-${ENV}-aurora-pg-instance-${i}"
  echo "⛔ Trying to delete RDS instance $INSTANCE_ID..."
  aws rds delete-db-instance \
    --region $REGION \
    --db-instance-identifier "$INSTANCE_ID" \
    --skip-final-snapshot || echo "⚠️ RDS Instance $INSTANCE_ID not found or already deleted"
done

echo "🧼 Cleaning up Terraform state files..."
rm -f terraform.tfstate terraform.tfstate.backup
rm -rf .terraform

echo "✅ Cleanup complete!"
