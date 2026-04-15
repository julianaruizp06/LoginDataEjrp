ACCOUNT_ID=$(aws sts get-caller-identity --profile logidata --query Account --output text)

cat > terraform.tfvars <<EOF
region      = "us-east-2"
profile     = "logidata"
bucket_name = "logidata-tfstate-${ACCOUNT_ID}"
EOF