#   TODO# Directory: 0-directories

## Description
This Terraform module is responsible for creating directories in **SAP BTP**. Directories are used to organize subaccounts and manage resources in a structured way.

## Created Resources
- **btp_directory.app_dev_rpa**: Creates the `APP_DEV_RPA` directory with a description and standardized labels.

## Variables
This module does not receive variables at the moment. However, it uses default labels defined in the `locals` block.

## Default Labels
The labels applied to the directory include:
- `created_at`: Timestamp of creation
- `owner`: Responsible team (`sre-team`)
- `project`: Project name (`terraform`)
- `team`: Team name associated with the directory

## Usage Example
To use this module in another Terraform module:

```hcl
module "directories" {
  source = "../modules/0-directories"
  
  providers = {
    btp = btp
  }
}
```

## Dependencies
- The `btp` provider must be configured in Terraform.

## Future Improvements
- Allow directory parameterization via `variables.tf`
- Support multiple directories using `for_each`
