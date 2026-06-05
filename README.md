# Project Bedrock – Infrastructure

This repository contains the Terraform and Kubernetes configuration files to provision and deploy Project Bedrock.

---

## 🛠️ Prerequisites

Ensure you have the following installed:
- [AWS CLI](https://aws.amazon.com/cli/)
- [Terraform](https://www.terraform.io/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)

Configure your AWS credentials using the required named profile:
```bash
aws configure --profile abdulmalik_aws
```

---

## 🚀 Quick Start & Deployment

### 1. Bootstrap State Bucket
Create the S3 bucket to store the remote Terraform state file:
```bash
export AWS_PROFILE=abdulmalik_aws
bash scripts/bootstrap-state.sh
```

### 2. Provision Infrastructure with Terraform
Initialize, validate, and apply the Terraform configuration:
```bash
cd terraform/prod
terraform init
terraform validate
terraform apply -auto-approve
```

### 3. Configure Kubernetes Access
Generate the kubeconfig file to connect to the EKS cluster:
```bash
aws eks update-kubeconfig --region us-east-1 --name project-bedrock-cluster --profile abdulmalik_aws
```

### 4. Apply Kubernetes Manifests
Deploy the RBAC and Ingress rules:
```bash
cd ../../
kubectl apply -f k8s/rbac.yaml
kubectl apply -f k8s/ingress.yaml
```

---

## 🔍 Verification

### Test S3/Lambda Event Logging
Upload a file to test the image-processing Lambda:
```bash
aws s3 cp scripts/lambda/index.py s3://bedrock-assets-alt-soe-2025-350/test.py --profile abdulmalik_aws
```
Check CloudWatch log group `/aws/lambda/bedrock-assets-processor` to verify the entry:
`Image received: test.py`

### Test Developer Access (RBAC)
Verify that the `bedrock-dev-view` role can view pods but cannot delete resources:
```bash
# Verify read access
kubectl get pods -n retail-app

# Verify write access is forbidden (should fail)
kubectl delete pod --all -n retail-app
```
