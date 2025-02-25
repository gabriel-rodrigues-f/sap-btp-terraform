# Module: 5-services

## Description
This Terraform module provisions **Cloud Foundry services** within the SAP BTP environment. It ensures that necessary managed services, such as **Application Logs**, are instantiated in the appropriate Cloud Foundry space.

## Created Resources

### Cloud Foundry Services
- **data.cloudfoundry_service.application_logs**: Retrieves metadata for the **Application Logs** service.
- **cloudfoundry_service_instance.dev-autoscaler**: Creates a **managed** service instance of **Application Logs** in the specified Cloud Foundry space.

## Variables

| Name | Description | Type |
|------|------------|------|
| `app_dev_rpa_dev_space` | Reference to the target Cloud Foundry space. | `any` |

## Usage Example
To use this module in another Terraform module:

```hcl
module "services" {
  source                = "../modules/5-services"
  app_dev_rpa_dev_space = module.environments.app_dev_rpa_dev_space

  depends_on = [module.environments]
}
