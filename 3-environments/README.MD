# Module: 3-environments

## Description
This Terraform module is responsible for creating and configuring **environments** within an SAP BTP subaccount. It provisions a **Cloud Foundry environment**, defines a space (`dev`), and assigns quotas and roles.

## Created Resources

### Environment Instance
- **btp_subaccount_environment_instance.app_dev_rpa**: Creates a Cloud Foundry environment in the subaccount.

### Cloud Foundry Resources
- **cloudfoundry_space.dev**: Creates a `dev` space within the Cloud Foundry environment.
- **cloudfoundry_space_quota.dev**: Defines a quota plan (`medium`) for the `dev` space.
- **cloudfoundry_space_role.admin**: Assigns the **Space Developer** role to the subaccount administrator.

## Variables

| Name | Description | Type |
|------|------------|------|
| `app_dev_rpa_subaccount` | Reference to the target subaccount (`btp_subaccount`). | `any` |
| `subaccount_admin` | Default subaccount administrator. | `string` |

## Usage Example
To use this module in another Terraform module:

```hcl
module "environments" {
  source                 = "../modules/3-environments"
  app_dev_rpa_subaccount = module.subaccounts.app_dev_rpa_subaccount
  subaccount_admin       = var.subaccount_admin

  depends_on = [module.entitlements]
}
