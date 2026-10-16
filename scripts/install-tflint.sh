#!/usr/bin/env bash
# Instala uma versão FIXA do tflint em <destino>/tflint, conferindo o SHA-256
# publicado na release. Uso: scripts/install-tflint.sh <versão> <destino>
set -euo pipefail

version="${1:?informe a versão, ex.: 0.64.0}"
dest="${2:?informe o diretório de destino, ex.: .venv/bin}"

os="$(uname -s | tr '[:upper:]' '[:lower:]')"
arch="$(uname -m)"
case "$arch" in
  x86_64) arch="amd64" ;;
  aarch64 | arm64) arch="arm64" ;;
  *) echo "Arquitetura não suportada: $arch" >&2; exit 1 ;;
esac

# (lê a versão numa variável: `cmd | grep -q` + pipefail falharia por SIGPIPE)
if [[ -x "$dest/tflint" ]] && [[ "$("$dest/tflint" --version)" == *"version $version"* ]]; then
  echo "tflint $version já instalado em $dest"
  exit 0
fi

asset="tflint_${os}_${arch}.zip"
base="https://github.com/terraform-linters/tflint/releases/download/v${version}"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

curl -fsSL -o "$tmp/$asset" "$base/$asset"
curl -fsSL -o "$tmp/checksums.txt" "$base/checksums.txt"

expected="$(awk -v f="$asset" '$2 == f { print $1 }' "$tmp/checksums.txt")"
actual="$(shasum -a 256 "$tmp/$asset" | awk '{ print $1 }')"
if [[ -z "$expected" || "$expected" != "$actual" ]]; then
  echo "Checksum inválido para $asset (esperado '$expected', obtido '$actual')" >&2
  exit 1
fi

mkdir -p "$dest"
unzip -oq "$tmp/$asset" -d "$tmp/out"
install -m 0755 "$tmp/out/tflint" "$dest/tflint"
echo "tflint $version instalado em $dest/tflint"
