# AWS Terraform Configuration with Security Group

This project demonstrates how to provision AWS EC2 instances using Terraform, including configuration for security groups and key pairs.

## Directory Structure

```
AWS_config_with_SG/
  instances/
    main.tf           # Main Terraform configuration
    outputs.tf        # Output values
    provider.tf       # AWS provider configuration
    version.tf        # Terraform version constraints
  keys/
    aws_key           # Private key for EC2 access
    aws_key.pub       # Public key for EC2 access
```

## Prerequisites
- [Terraform](https://www.terraform.io/downloads.html) installed
- AWS credentials configured (via environment variables or AWS CLI)

## Usage
1. Initialize Terraform:
   ```powershell
   terraform init
   ```
2. Review the execution plan:
   ```powershell
   terraform plan
   ```
3. Apply the configuration:
   ```powershell
   terraform apply
   ```
4. View outputs:
   ```powershell
   terraform output
   ```

## Files
- **main.tf**: Defines resources (EC2, security group, etc.)
- **outputs.tf**: Specifies output values (e.g., public IP)
- **provider.tf**: AWS provider setup
- **version.tf**: Required Terraform version
- **keys/**: SSH key pair for EC2 access

## Notes
- Ensure your AWS credentials have sufficient permissions.
- The AMI filter in `main.tf` may need adjustment for your region or requirements.
- Keep your private key (`aws_key`) secure.


## In `instances/` Folder

### provider.tf
Configures the AWS provider and sets the region to `us-east-2`. This tells Terraform to use AWS resources in the Ohio region.

### version.tf
Specifies required Terraform and AWS provider versions:
- Requires Terraform version `>= 1.2.8`.
- Uses the AWS provider from HashiCorp, version `~> 4.20`.
This ensures compatibility and stability for your infrastructure code.

### outputs.tf
Defines output values to display after applying the configuration:
- **public_dns**: Shows the public DNS name of the EC2 instance.
- **public_ip**: Shows the public IP address of the EC2 instance.
These outputs help you quickly access your deployed instance.


## main.tf Explanation

The `main.tf` file provisions the following AWS resources:

### Security Groups
- **aws_security_group.sg_ssh**: Allows inbound SSH (port 22) from anywhere and outbound traffic to anywhere.
- **aws_security_group.sg_https**: Allows inbound HTTPS (port 443) only from the `192.168.0.0/16` subnet and outbound traffic to anywhere.
- **aws_security_group.sg_http**: Allows inbound HTTP (port 80) from anywhere and outbound traffic to anywhere.

### Key Pair
- **aws_key_pair.deployer**: Creates an AWS key pair named `aws_key` using the public key from `../keys/aws_key.pub`. This key is used for SSH access to EC2 instances.

### EC2 Instance
- **aws_instance.sg-instance**: Launches an EC2 instance with:
   - The specified AMI (`ami-097a2df4ac947655f`)
   - Instance type `t2.micro`
   - The created key pair for SSH access
   - All three security groups attached
   - A tag `Name = "SG-VM"` for identification
