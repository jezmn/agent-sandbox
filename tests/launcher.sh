#!/usr/bin/env bash
set -euo pipefail
launcher="$(dirname "$(dirname "$(realpath "$0")")")/agent-sandbox"

bash -n "$launcher"
"$launcher" --help >/dev/null
help=$("$launcher" --command /usr/bin/printf --help)
[[ "$help" == *'--host'* && "$help" == *'FORMAT'* ]]
help=$("$launcher" --command /sandbox/printf --ro /usr/bin/printf /sandbox/printf --help)
[[ "$help" == *'--host'* && "$help" == *'FORMAT'* ]]

# Program arguments, including spaces, must reach the selected executable.
[[ $("$launcher" --command /usr/bin/printf "%s" "two words") == 'two words' ]]
[[ $("$launcher" -- /usr/bin/printf "%s" "two words") == 'two words' ]]
[[ $("$launcher" --command /usr/bin/printf --host "%s" "two words") == 'two words' ]]
# Host mode uses the source when the sandbox command is a remapped executable.
[[ $("$launcher" --command /sandbox/printf --ro /usr/bin/printf /sandbox/printf --host "%s" "two words") == 'two words' ]]
[[ $("$launcher" --ro /usr/bin/printf /sandbox/printf --command /sandbox/printf --host "%s" "two words") == 'two words' ]]
[[ $("$launcher" --command /sandbox/printf --ro /usr/bin/printf /sandbox/printf "%s" "two words") == 'two words' ]]

# Host mode keeps the environment; sandbox mode clears it.
export AGENT_SANDBOX_TEST=present
"$launcher" --command /usr/bin/printenv --host AGENT_SANDBOX_TEST >/dev/null
if "$launcher" --command /usr/bin/printenv AGENT_SANDBOX_TEST >/dev/null; then exit 1; fi
"$launcher" --command /usr/bin/sh -p "$(dirname "$launcher")" -c 'test -f agent-sandbox'

# --path makes a mounted binary findable by name inside the sandbox.
[[ $("$launcher" --command agent-sandbox-path-test --ro /usr/bin/printf /opt/agent-sandbox-path-test --path /opt "%s" "two words") == 'two words' ]]
if "$launcher" --command agent-sandbox-path-test --ro /usr/bin/printf /opt/agent-sandbox-path-test "%s" "two words"; then exit 1; fi
if "$launcher" --command /usr/bin/sh --path /nonexistent-dir-xyz -c true; then exit 1; fi
if "$launcher" --path; then exit 1; fi

# Mode message goes to stderr; stdout stays clean for pipes.
[[ $("$launcher" --command /usr/bin/true 2>&1 >/dev/null) == *'chat mode'* ]]
[[ $("$launcher" --command /usr/bin/true -p /tmp 2>&1 >/dev/null) == *'project /tmp'* ]]

if "$launcher" --command; then exit 1; fi
if "$launcher" --host; then exit 1; fi
printf 'Launcher checks passed.\n'
