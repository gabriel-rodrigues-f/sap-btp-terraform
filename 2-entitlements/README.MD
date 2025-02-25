# Module: 2-entitlements

## Description
This Terraform module is responsible for assigning **entitlements** to an SAP BTP subaccount. Entitlements define the services and plans that a subaccount can consume.

## Created Resources
- **btp_subaccount_entitlement.cloud_foundry**: Grants **Application Runtime** (`APPLICATION_RUNTIME`) with the **MEMORY** plan.
- **btp_subaccount_entitlement.business_application_studio**: Grants **Business Application Studio** (`sapappstudiotrial`) with the **trial** plan.

## Variables
| Name | Description | Type |
|------|------------|------|
| `app_dev_rpa_subaccount` | Reference to the target subaccount (`btp_subaccount`). | `any` |

## Usage Example
To use this module in another Terraform module:

```hcl
module "entitlements" {
  source                 = "../modules/2-entitlements"
  app_dev_rpa_subaccount = module.subaccounts.app_dev_rpa_subaccount

  depends_on = [module.subaccounts]
}
