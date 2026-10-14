#!/usr/bin/env bash
set -euo pipefail
wrapper="${OPENCODE_SANDBOX:-$HOME/.local/bin/opencode-sandbox}"
out=$(cd /tmp && "$wrapper" -p --dry-run 2>&1)
[[ "$out" == *"agent-sandbox: project /tmp"* ]]
[[ "$out" == *"/opt/opencode --standalone"* ]]
out=$("$wrapper" --dry-run 2>&1)
[[ "$out" == *"chat mode"* ]]
[[ "$out" == *"--standalone"* ]]
printf 'Wrapper checks passed.\n'
