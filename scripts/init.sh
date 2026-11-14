#!/usr/bin/env bash
# Bootstrapper temporal para levantar el stack completo con Terraform
# usando el perfil AWS "e2ops_admin".
#
# Uso:
#   ./scripts/init.sh            # init + plan + apply (pide confirmación)
#   ./scripts/init.sh plan       # solo init + plan
#   ./scripts/init.sh destroy    # destruye el stack (pide confirmación)
#
# NOTA: este script es para probar la demo de la charla. Una vez
# verificado el deploy, se saca del repo (ver comentario en README.md).
set -euo pipefail

AWS_PROFILE_NAME="e2ops_admin"
APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="$APP_DIR/terraform"
ACTION="${1:-apply}"

echo "== Bootstrapper Terraform (perfil AWS: $AWS_PROFILE_NAME) =="

# Verifica que el perfil exista antes de hacer nada contra AWS.
if ! aws configure list-profiles 2>/dev/null | grep -qx "$AWS_PROFILE_NAME"; then
  echo "Error: no se encontró el perfil AWS '$AWS_PROFILE_NAME'." >&2
  echo "Configuralo con: aws configure --profile $AWS_PROFILE_NAME" >&2
  exit 1
fi

export AWS_PROFILE="$AWS_PROFILE_NAME"

echo "Identidad activa:"
aws sts get-caller-identity --profile "$AWS_PROFILE_NAME"

cd "$TF_DIR"
terraform init -upgrade

case "$ACTION" in
  plan)
    terraform plan
    ;;
  destroy)
    terraform destroy
    ;;
  apply)
    terraform plan -out=tfplan
    terraform apply tfplan
    rm -f tfplan
    echo ""
    echo "Listo. Outputs:"
    terraform output
    ;;
  *)
    echo "Acción desconocida: $ACTION (usar: apply | plan | destroy)" >&2
    exit 1
    ;;
esac
