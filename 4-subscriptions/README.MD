# Module: 4-subscriptions

## Description
This Terraform module is responsible for managing **subscriptions** within an SAP BTP subaccount. It provisions subscriptions to necessary services, such as **SAP Business Application Studio**.

## Created Resources

### Subscriptions
- **btp_subaccount_subscription.business_application_studio**: Subscribes the subaccount to the **SAP Business Application Studio** service.

## Variables

| Name | Description | Type |
|------|------------|------|
| `app_dev_rpa_subaccount` | Reference to the target subaccount (`btp_subaccount`). | `any` |

## Usage Example
To use this module in another Terraform module:

```hcl
module "subscriptions" {
  source                 = "../modules/4-subscriptions"
  app_dev_rpa_subaccount = module.subaccounts.app_dev_rpa_subaccount

  depends_on = [module.entitlements]
}
