"""Filtros da auditoria de FinOps.

Lógica de dados fica em Python (testável e legível), não em Jinja aninhado.
"""


def finops_audit(resources_by_type, required_keys):
    """Retorna uma linha por recurso, com as labels obrigatórias que faltam.

    resources_by_type: {"cf-space": [<recurso da API v3>, ...], ...}
    required_keys: ["cost-center", "environment", ...]
    """
    rows = []
    for resource_type, resources in resources_by_type.items():
        for resource in resources or []:
            labels = (resource.get("metadata") or {}).get("labels") or {}
            missing = sorted(key for key in required_keys if not labels.get(key))
            rows.append(
                {
                    "type": resource_type,
                    "name": resource.get("name", ""),
                    "guid": resource.get("guid", ""),
                    "labels": labels,
                    "missing": missing,
                    "compliant": not missing,
                }
            )
    return rows


class FilterModule:
    """Registra os filtros da role finops_compliance."""

    def filters(self):
        return {"finops_audit": finops_audit}
