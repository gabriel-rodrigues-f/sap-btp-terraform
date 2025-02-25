#   TODO# Module: 1-subaccounts

## Description
This Terraform module is responsible for creating **subaccounts** in **SAP BTP**. Subaccounts allow for the isolation of applications, services, and entitlements within a structured environment.

## Created Resources
- **btp_subaccount.app_dev_rpa**: Creates a subaccount named `${upper(var.env)}_APP_DEV_RPA` in the specified **directory**.
- **btp_subaccount_role_collection_assignment.this**: Assigns the `Subaccount Administrator` role to a user.

## Variables
| Name | Description | Type |
|------|------------|------|
| `env` | Corporate environment identifier (e.g., `QA`, `PRD`). | `string` |
| `app_dev_rpa_directory` | Reference to the parent directory (`btp_directory`). | `any` |
| `subaccount_admin` | Email or username of the subaccount administrator. | `string` |

## Default Labels
The subaccount receives the following labels:
- `created_at`: Timestamp of creation
- `owner`: Responsible team (`sre-team`)
- `project`: Project name (`terraform`)
- `team`: Team associated with the subaccount (`app-dev-rpa-team`)

## Usage Example
To use this module in another Terraform module:

```hcl
module "subaccounts" {
  source                = "../modules/1-subaccounts"
  env                   = var.env
  app_dev_rpa_directory = module.directories.app_dev_rpa_directory
  subaccount_admin      = var.subaccount_admin

  providers = {
    btp = btp
  }
}
