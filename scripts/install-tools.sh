#!/usr/bin/env bash
# Instala herramientas de calidad para Terraform (tflint, gitleaks, pre-commit)
set -euo pipefail

INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"
mkdir -p "$INSTALL_DIR"

TFLINT_VERSION="v0.55.0"
GITLEAKS_VERSION="v8.24.0"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

if command -v tflint >/dev/null 2>&1; then
  echo "tflint ya instalado: $(tflint --version | head -n1)"
else
  echo "Descargando tflint $TFLINT_VERSION..."
  curl -fsSL "https://github.com/terraform-linters/tflint/releases/download/${TFLINT_VERSION}/tflint_linux_amd64.zip" -o "$TMP/tflint.zip"
  unzip -q "$TMP/tflint.zip" -d "$TMP"
  install -m 0755 "$TMP/tflint" "$INSTALL_DIR/tflint"
  echo "✔ tflint instalado en $INSTALL_DIR/tflint"
fi

if command -v gitleaks >/dev/null 2>&1; then
  echo "gitleaks ya instalado: $(gitleaks version)"
else
  echo "Descargando gitleaks $GITLEAKS_VERSION..."
  curl -fsSL "https://github.com/gitleaks/gitleaks/releases/download/${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION#v}_linux_x64.tar.gz" -o "$TMP/gitleaks.tar.gz"
  tar -xzf "$TMP/gitleaks.tar.gz" -C "$TMP"
  install -m 0755 "$TMP/gitleaks" "$INSTALL_DIR/gitleaks"
  echo "✔ gitleaks instalado en $INSTALL_DIR/gitleaks"
fi

if command -v pre-commit >/dev/null 2>&1; then
  echo "pre-commit ya instalado: $(pre-commit --version)"
else
  echo "Instalando pre-commit..."
  pip install --user pre-commit --break-system-packages
  echo "✔ pre-commit instalado"
fi

if command -v infracost >/dev/null 2>&1; then
  echo "infracost ya instalado: $(infracost --version | head -n1)"
else
  echo "Descargando e instalando infracost..."
  curl -fsSL "https://github.com/infracost/infracost/releases/latest/download/infracost-linux-amd64.tar.gz" | tar -xz -C "$INSTALL_DIR"
  chmod +x "$INSTALL_DIR/infracost-linux-amd64"
  ln -sf "$INSTALL_DIR/infracost-linux-amd64" "$INSTALL_DIR/infracost"
  echo "✔ infracost instalado en $INSTALL_DIR/infracost"
fi

echo "Todas las herramientas de calidad están instaladas."
