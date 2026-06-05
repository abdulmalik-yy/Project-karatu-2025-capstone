#!/usr/bin/env bash
# =============================================================================
# bootstrap-state.sh
#
# PURPOSE:
#   Create the S3 bucket that Terraform uses to store its state file.
#   This script must be run ONCE, BEFORE running 'terraform init'.
#   After this script succeeds, Terraform's backend.tf will work.
#
# WHY DO WE NEED THIS?
#   Terraform needs to store a "state file" so it remembers what resources
#   it already created. We store this file in S3 so that:
#     - The CI/CD pipeline (GitHub Actions) can read/write it.
#     - Multiple team members share the same state.
#   But to create the S3 bucket, we can't use Terraform (chicken-and-egg
#   problem), so we use the AWS CLI instead.
#
# PREREQUISITES:
#   - AWS CLI installed and configured (run: aws configure)
#   - The IAM user/role must have permissions to create S3 buckets
#
# USAGE:
#   chmod +x scripts/bootstrap-state.sh
#   ./scripts/bootstrap-state.sh
# =============================================================================

set -euo pipefail  # Exit immediately on error

# ── Configuration ─────────────────────────────────────────────────────────────
BUCKET_NAME="bedrock-tfstate-alt-soe-025-350"
REGION="us-east-1"

echo "=============================================="
echo "  Project Bedrock -- Terraform State Bootstrap"
echo "=============================================="
echo ""
echo "Bucket : ${BUCKET_NAME}"
echo "Region : ${REGION}"
echo ""

# ── Step 1: Create the S3 bucket ──────────────────────────────────────────────
echo "[1/4] Creating S3 bucket..."

# Check if bucket already exists to make this script idempotent (safe to re-run)
if aws s3api head-bucket --bucket "${BUCKET_NAME}" 2>/dev/null; then
  echo "      Bucket already exists -- skipping creation."
else
  # us-east-1 is special: it does NOT accept a LocationConstraint parameter
  aws s3api create-bucket \
    --bucket "${BUCKET_NAME}" \
    --region "${REGION}"
  echo "      Bucket created."
fi

# ── Step 2: Enable Versioning ─────────────────────────────────────────────────
# Versioning means S3 keeps old copies of the state file.
# If Terraform corrupts the state, you can roll back to a previous version.
echo "[2/4] Enabling versioning on the bucket..."
aws s3api put-bucket-versioning \
  --bucket "${BUCKET_NAME}" \
  --versioning-configuration Status=Enabled
echo "      Versioning enabled."

# ── Step 3: Enable Server-Side Encryption ─────────────────────────────────────
# Encrypt the state file at rest using AWS-managed keys (SSE-S3).
# The state file contains sensitive data like database passwords!
echo "[3/4] Enabling server-side encryption..."
aws s3api put-bucket-encryption \
  --bucket "${BUCKET_NAME}" \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'
echo "      Encryption enabled."

# ── Step 4: Block all public access ───────────────────────────────────────────
# The state file must NEVER be public -- it contains secrets!
echo "[4/4] Blocking all public access..."
aws s3api put-public-access-block \
  --bucket "${BUCKET_NAME}" \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
echo "      Public access blocked."

echo ""
echo "=============================================="
echo "  Bootstrap complete!"
echo "  You can now run: cd terraform/prod && terraform init"
echo "=============================================="
