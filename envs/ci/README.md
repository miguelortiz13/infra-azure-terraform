# envs/ci: recursos persistentes de CI

Registro de contenedores e identidad de GitHub Actions del pipeline de
[online-boutique-ci](https://github.com/miguelortiz13/online-boutique-ci) (P2).

A diferencia de `envs/dev`, **no se destruye al apagar el lab**: guarda las
imágenes firmadas y sus atestaciones SBOM.

| Recurso | Nombre |
|---|---|
| Grupo de recursos | `rg-devops-sre-ci-eastus2` |
| ACR Basic (~USD 5/mes) | `acrdevsrelab01` |
| App registration (OIDC) | `gh-online-boutique-ci`: `AcrPush` + `Reader` sobre el ACR |

Se creó con `az` y se importó con `imports.tf`.

```bash
cd envs/ci
terraform init
terraform plan
```
