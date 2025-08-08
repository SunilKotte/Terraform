# SSH Keys for AWS EC2 Access

This folder contains the SSH key pair used to access your AWS EC2 instances provisioned by Terraform.

## Files
- **aws_key**: Private key file. Keep this file secure and do not share it publicly.
- **aws_key.pub**: Public key file. This is used by Terraform to configure EC2 instance access.

## Usage
- The public key (`aws_key.pub`) is referenced in the Terraform configuration to create an AWS key pair resource.
- The private key (`aws_key`) is used to SSH into your EC2 instances after deployment.

## Security
- **Do not commit your private key (`aws_key`) to public repositories.**
- Restrict permissions on the private key file to prevent unauthorized access.
- Rotate keys periodically and remove unused keys.

## Generating New Keys
To generate a new key pair, use:
```powershell
ssh-keygen -t ed25519
```

- Follow the prompts to specify a file name and passphrase.
- Ensure you save the private key securely.

This will create `aws_key` (private) and `aws_key.pub` (public) files in this folder.

## Notes
- Only the public key is safe to share or use in Terraform configurations.
- The private key should remain confidential and protected.
