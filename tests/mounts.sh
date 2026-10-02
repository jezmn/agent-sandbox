#!/usr/bin/env bash
set -euo pipefail
launcher="$(dirname "$(dirname "$(realpath "$0")")")/agent-sandbox"

private="$(mktemp -d)"
trap 'rm -rf "$private"' EXIT
printf 'original' > "$private/secret"

if "$launcher" -p "$HOME" -- /usr/bin/true; then exit 1; fi
if "$launcher" -p / -- /usr/bin/true; then exit 1; fi
if "$launcher" --ro / -- /usr/bin/true; then exit 1; fi
if "$launcher" --rw / -- /usr/bin/true; then exit 1; fi
if "$launcher" --ro "$private/missing" -- /usr/bin/true; then exit 1; fi

"$launcher" -- /usr/bin/test ! -e "$private/secret"
"$launcher" --ro "$private/secret" -- /usr/bin/test -f "$private/secret"

if printf changed | "$launcher" --ro "$private/secret" -- /usr/bin/tee -a "$private/secret" >/dev/null; then exit 1; fi
test "$(cat "$private/secret")" = original

printf written | "$launcher" --rw "$private" -- /usr/bin/tee "$private/result" >/dev/null
test "$(cat "$private/result")" = written

# Optional DEST remaps to a different path inside.
"$launcher" --ro "$private/secret" /alt/secret -- /usr/bin/test -f /alt/secret
"$launcher" -- /usr/bin/test ! -e /alt/secret

printf 'Mount checks passed.\n'
