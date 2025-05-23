#!/bin/bash

# scripts/deploy.sh
# AWS Global Disaster Recovery Platform Deployment Script

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if AWS CLI is configured
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS CLI is not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    print_success "AWS CLI is configured"
}

# Function to check if Terraform is installed
check_terraform() {
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install it first."
        exit 1
    fi
    
    print_success "Terraform is available"
}

# Function to deploy primary region
deploy_primary() {
    print_status "Deploying Primary Region (us-east-1)..."
    
    cd terraform/environments/primary
    
    print_status "Initializing Terraform..."
    terraform init
    
    print_status "Validating Terraform configuration..."
    terraform validate
    
    print_status "Planning deployment..."
    terraform plan -out=primary.tfplan
    
    read -p "Do you want to apply the primary region deployment? (yes/no): " confirm
    if [[ $confirm == "yes" ]]; then
        print_status "Applying primary region configuration..."
        terraform apply primary.tfplan
        print_success "Primary region deployed successfully!"
        
        # Get primary database identifier for DR region
        DB_IDENTIFIER=$(terraform output -raw db_instance_identifier)
        echo "export PRIMARY_DB_IDENTIFIER=$DB_IDENTIFIER" > ../../../primary_outputs.env
        
        # Get S3 bucket ARN for cross-region replication
        S3_BUCKET_ARN=$(terraform output -raw s3_bucket_arn)
        echo "export PRIMARY_S3_BUCKET_ARN=$S3_BUCKET_ARN" >> ../../../primary_outputs.env
        
        print_success "Primary region outputs saved to primary_outputs.env"
    else
        print_warning "Primary region deployment cancelled"
        exit 0
    fi
    
    cd ../../..
}

# Function to deploy DR region
deploy_dr() {
    print_status "Deploying DR Region (us-west-2)..."
    
    if [[ ! -f "primary_outputs.env" ]]; then
        print_error "Primary region outputs not found. Please deploy primary region first."
        exit 1
    fi
    
    source primary_outputs.env
    
    cd terraform/environments/dr
    
    print_status "Initializing Terraform..."
    terraform init
    
    print_status "Validating Terraform configuration..."
    terraform validate
    
    print_status "Planning DR deployment..."
    terraform plan -var="source_db_identifier=$PRIMARY_DB_IDENTIFIER" -out=dr.tfplan
    
    read -p "Do you want to apply the DR region deployment? (yes/no): " confirm
    if [[ $confirm == "yes" ]]; then
        print_status "Applying DR region configuration..."
        terraform apply dr.tfplan
        print_success "DR region deployed successfully!"
    else
        print_warning "DR region deployment cancelled"
        exit 0
    fi
    
    cd ../../..
}

# Function to setup S3 cross-region replication
setup_s3_replication() {
    print_status "Setting up S3 cross-region replication..."
    
    if [[ ! -f "primary_outputs.env" ]]; then
        print_error "Primary region outputs not found."
        exit 1
    fi
    
    source primary_outputs.env
    
    # Get DR S3 bucket ARN
    cd terraform/environments/dr
    DR_S3_BUCKET_ARN=$(terraform output -raw s3_bucket_arn)
    cd ../../..
    
    # Update primary region with DR bucket ARN for replication
    cd terraform/environments/primary
    terraform plan -var="enable_cross_region_replication=true" -var="destination_bucket_arn=$DR_S3_BUCKET_ARN" -out=replication.tfplan
    
    read -p "Do you want to enable S3 cross-region replication? (yes/no): " confirm
    if [[ $confirm == "yes" ]]; then
        terraform apply replication.tfplan
        print_success "S3 cross-region replication enabled!"
    else
        print_warning "S3 replication setup cancelled"
    fi
    
    cd ../../..
}

# Function to display deployment summary
show_summary() {
    print_status "Deployment Summary:"
    echo "===================="
    
    if [[ -f "primary_outputs.env" ]]; then
        source primary_outputs.env
        
        cd terraform/environments/primary
        PRIMARY_ALB_DNS=$(terraform output -raw alb_dns_name)
        PRIMARY_S3_BUCKET=$(terraform output -raw s3_bucket_name)
        cd ../../..
        
        cd terraform/environments/dr
        DR_ALB_DNS=$(terraform output -raw alb_dns_name)
        DR_S3_BUCKET=$(terraform output -raw s3_bucket_name)
        cd ../../..
        
        echo ""
        print_success "PRIMARY REGION (us-east-1):"
        echo "  - Load Balancer: http://$PRIMARY_ALB_DNS"
        echo "  - S3 Bucket: $PRIMARY_S3_BUCKET"
        echo "  - Database: $PRIMARY_DB_IDENTIFIER"
        echo ""
        print_success "DR REGION (us-west-2):"
        echo "  - Load Balancer: http://$DR_ALB_DNS"
        echo "  - S3 Bucket: $DR_S3_BUCKET"
        echo "  - Read Replica: Available"
        echo ""
        print_warning "Next Steps:"
        echo "  1. Set up Route 53 health checks and failover routing"
        echo "  2. Configure CloudWatch monitoring and alarms"
        echo "  3. Test failover scenarios"
        echo "  4. Upload sample data to test S3 replication"
    fi
}

# Main deployment flow
main() {
    print_status "AWS Global Disaster Recovery Platform Deployment"
    print_status "=============================================="
    
    # Pre-flight checks
    check_aws_cli
    check_terraform
    
    # Deployment options
    echo ""
    echo "Deployment Options:"
    echo "1. Deploy Primary Region only"
    echo "2. Deploy DR Region only (requires primary to be deployed first)"
    echo "3. Deploy Both Regions"
    echo "4. Setup S3 Cross-Region Replication"
    echo "5. Show Deployment Summary"
    echo ""
    
    read -p "Select option (1-5): " option
    
    case $option in
        1)
            deploy_primary
            show_summary
            ;;
        2)
            deploy_dr
            show_summary
            ;;
        3)
            deploy_primary
            deploy_dr
            setup_s3_replication
            show_summary
            ;;
        4)
            setup_s3_replication
            ;;
        5)
            show_summary
            ;;
        *)
            print_error "Invalid option selected"
            exit 1
            ;;
    esac
    
    print_success "Deployment script completed!"
}

# Run main function
main "$@"
