#!/bin/bash
# ── Terraform Bootstrap Script ────────────────────────────────────────────────
# Run this ONCE before terraform init
# Creates S3 bucket for remote state storage
# =============================================================================

set -e  # exit on any error

# ── Configuration ─────────────────────────────────────────────────────────────
BUCKET_NAME="devops-bank-app-tfstate"
REGION="us-west-2"

# ── Colors for output ─────────────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}  Terraform State Bootstrap Script      ${NC}"
echo -e "${YELLOW}========================================${NC}"

# ── Check AWS CLI is installed ────────────────────────────────────────────────
echo -e "\n${YELLOW}[1/5] Checking AWS CLI...${NC}"
if ! command -v aws &> /dev/null; then
  echo -e "${RED}ERROR: AWS CLI not found. Install it first.${NC}"
  exit 1
fi
echo -e "${GREEN}✔ AWS CLI found${NC}"

# ── Check AWS credentials are configured ──────────────────────────────────────
echo -e "\n${YELLOW}[2/5] Checking AWS credentials...${NC}"
if ! aws sts get-caller-identity &> /dev/null; then
  echo -e "${RED}ERROR: AWS credentials not configured. Run: aws configure${NC}"
  exit 1
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo -e "${GREEN}✔ Authenticated as Account: ${ACCOUNT_ID}${NC}"

# ── Check if bucket already exists ───────────────────────────────────────────
echo -e "\n${YELLOW}[3/5] Checking if S3 bucket exists...${NC}"
if aws s3 ls "s3://${BUCKET_NAME}" &> /dev/null; then
  echo -e "${GREEN}✔ Bucket already exists: ${BUCKET_NAME}${NC}"
  echo -e "${YELLOW}  Skipping creation — applying settings only${NC}"
else
  # ── Create S3 bucket ──────────────────────────────────────────────────────
  echo -e "\n${YELLOW}[3/5] Creating S3 bucket...${NC}"
  aws s3 mb "s3://${BUCKET_NAME}" --region "${REGION}"
  echo -e "${GREEN}✔ Bucket created: ${BUCKET_NAME}${NC}"
fi

# ── Enable versioning ─────────────────────────────────────────────────────────
echo -e "\n${YELLOW}[4/5] Enabling versioning...${NC}"
aws s3api put-bucket-versioning \
  --bucket "${BUCKET_NAME}" \
  --versioning-configuration Status=Enabled
echo -e "${GREEN}✔ Versioning enabled — old state files recoverable${NC}"

# ── Block all public access ───────────────────────────────────────────────────
echo -e "\n${YELLOW}[5/5] Blocking public access...${NC}"
aws s3api put-public-access-block \
  --bucket "${BUCKET_NAME}" \
  --public-access-block-configuration \
  "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
echo -e "${GREEN}✔ Public access blocked — state file is private${NC}"

# ── Enable server-side encryption ─────────────────────────────────────────────
aws s3api put-bucket-encryption \
  --bucket "${BUCKET_NAME}" \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'
echo -e "${GREEN}✔ Encryption enabled — state file encrypted at rest${NC}"

# ── Summary ───────────────────────────────────────────────────────────────────
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  Bootstrap Complete!                   ${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "\nBucket : ${BUCKET_NAME}"
echo -e "Region : ${REGION}"
echo -e "Account: ${ACCOUNT_ID}"
echo -e "\n${YELLOW}Next steps:${NC}"
echo -e "  1. Fill in terraform/terraform.tfvars with your values"
echo -e "  2. terraform init"
echo -e "  3. terraform plan"
echo -e "  4. terraform apply"