#!/bin/bash

# scripts/destroy.sh
# AWS Global Disaster Recovery Platform Destroy Script

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

# Function to destroy DR region
destroy_dr() {
    print_status "Destroying DR Region (us-west-2)..."
    
    cd terraform/environments/dr
    
    if [[ -f "terraform.tfstate" ]] || [[ -d ".terraform" ]]; then
        print_warning "This will destroy ALL resources in the DR region!"
        read -p "Are you sure you want to continue? Type 'yes' to confirm: " confirm
        
        if [[ $confirm == "yes" ]]; then
            print_status "Destroying DR region infrastructure..."
            
            if [[ -f "../../../primary_outputs.env" ]]; then
                source ../../../primary_outputs.env
                terraform destroy -var="source_db_identifier=$PRIMARY_DB_IDENTIFIER" -auto-approve
            else
                terraform destroy -auto-approve
            fi
            
            print_success "DR region destroyed successfully!"
        else
            print_warning "DR region destruction cancelled"
        fi
    else
        print_warning "No DR region infrastructure found to destroy"
    fi
    
    cd ../../..
}

# Function to destroy primary region
destroy_primary() {
    print_status "Destroying Primary Region (us-east-1)..."
    
    cd terraform/environments/primary
    
    if [[ -f "terraform.tfstate" ]] || [[ -d ".terraform" ]]; then
        print_warning "This will destroy ALL resources in the Primary region!"
        print_warning "This includes the production database and all data!"
        read -p "Are you sure you want to continue? Type 'yes' to confirm: " confirm
        
        if [[ $confirm == "yes" ]]; then
            print_status "Destroying primary region infrastructure..."
            terraform destroy -auto-approve
            print_success "Primary region destroyed successfully!"
            
            # Clean up environment file
            if [[ -f "../../../primary_outputs.env" ]]; then
                rm ../../../primary_outputs.env
                print_status "Cleaned up primary outputs file"
            fi
        else
            print_warning "Primary region destruction cancelled"
        fi
    else
        print_warning "No primary region infrastructure found to destroy"
    fi
    
    cd ../../..
}

# Function to clean up all Terraform state files
clean_terraform_state() {
    print_status "Cleaning up Terraform state files..."
    
    read -p "This will remove all Terraform state files. Continue? (yes/no): " confirm
    
    if [[ $confirm == "yes" ]]; then
        find terraform -name "*.tfstate*" -delete
        find terraform -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
        find terraform -name "*.tfplan" -delete
        
        if [[ -f "primary_outputs.env" ]]; then
            rm primary_outputs.env
        fi
        
        print_success "Terraform state files cleaned up"
    else
        print_warning "Cleanup cancelled"
    fi
}

# Main destroy flow
main() {
    print_status "AWS Global Disaster Recovery Platform Destroy Script"
    print_status "================================================="
    
    print_warning "WARNING: This script will destroy AWS resources and may incur costs!"
    print_warning "Make sure you have backups of any important data!"
    
    echo ""
    echo "Destroy Options:"
    echo "1. Destroy DR Region only"
    echo "2. Destroy Primary Region only"
    echo "3. Destroy Both Regions (DR first, then Primary)"
    echo "4. Clean up Terraform state files only"
    echo ""
    
    read -p "Select option (1-4): " option
    
    case $option in
        1)
            destroy_dr
            ;;
        2)
            destroy_primary
            ;;
        3)
            print_status "Destroying both regions (DR first to avoid dependency issues)..."
            destroy_dr
            destroy_primary
            ;;
        4)
            clean_terraform_state
            ;;
        *)
            print_error "Invalid option selected"
            exit 1
            ;;
    esac
    
    print_success "Destroy script completed!"
    print_warning "Please check your AWS console to confirm all resources are destroyed"
    print_warning "You may need to manually delete any remaining S3 bucket contents"
}

# Run main function
main "$@"
