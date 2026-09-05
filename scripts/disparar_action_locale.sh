#!/bin/bash
set -euo pipefail
echo "::warning::GitHub CLI não está autenticado neste ambiente. A action não pode ser disparada via 'gh' agora."
echo "Use o botão 'Run workflow' no GitHub Actions ou o script scripts/dispatch_action.ps1 com token válido."
exit 0
