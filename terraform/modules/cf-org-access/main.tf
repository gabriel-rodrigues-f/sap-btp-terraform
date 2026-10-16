#
# Papéis na ORG Cloud Foundry, em duas ondas:
#   1. organization_user para todos (torna a pessoa membro da org)
#   2. papéis adicionais (manager, auditor, billing manager)
# A ordem importa: o Cloud Foundry só aceita papel de space para quem já é
# membro da org, e o módulo cf-space recebe o org_id só depois das duas ondas.
#

locals {
  excluded = toset(var.exclude_users)

  members = toset([
    for user in distinct(flatten(values(var.roles))) : user
    if !contains(local.excluded, user)
  ])

  extra_roles = merge([
    for role, users in var.roles : {
      for user in users : "${role}|${user}" => {
        role = role
        user = user
      }
      if !contains(local.excluded, user)
    }
    if role != "organization_user"
  ]...)
}

resource "cloudfoundry_org_role" "member" {
  for_each = local.members

  org      = var.org_id
  type     = "organization_user"
  username = each.value
  origin   = var.user_origin
}

resource "cloudfoundry_org_role" "this" {
  for_each = local.extra_roles

  org      = var.org_id
  type     = each.value.role
  username = each.value.user
  origin   = var.user_origin

  depends_on = [cloudfoundry_org_role.member]
}
