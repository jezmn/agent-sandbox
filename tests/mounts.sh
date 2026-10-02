#!/usr/bin/env bash
set -euo pipefail
launcher="$(dirname "$(dirname "$(realpath "$0")")")/agent-sandbox"

private="$(mktemp -d)"
trap 'rm -rf "$private"' EXIT
printf 'original' >"$private/secret"

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

"$launcher" --ro "$private/secret" /alt/secret -- /usr/bin/test -f /alt/secret
"$launcher" -- /usr/bin/test ! -e /alt/secret

printf 'one' >"$private/one"
printf 'two' >"$private/two"
test "$("$launcher" --ro "$private/one,$private/two" -- /usr/bin/cat "$private/one")" = one
test "$("$launcher" --ro "$private/one,$private/two" -- /usr/bin/cat "$private/two")" = two
if "$launcher" --ro "$private/one,$private/two" /alt -- /usr/bin/true; then exit 1; fi
mkdir -p "$private/proj" "$private/proj/keys"
printf 'SECRET' >"$private/proj/.env"
printf 'KEY' >"$private/proj/keys/id_rsa"
hidden_bytes=$("$launcher" -p "$private/proj" --hide "$private/proj/.env,$private/proj/keys" -- /usr/bin/cat "$private/proj/.env" 2>/dev/null | /usr/bin/wc -c || true)
test "$hidden_bytes" = 0
hidden_entries=$("$launcher" -p "$private/proj" --hide "$private/proj/.env,$private/proj/keys" -- /usr/bin/ls "$private/proj/keys" | /usr/bin/wc -l)
test "$hidden_entries" = 0

# A flag-like DEST must fail instead of being swallowed.
if "$launcher" --ro "$private/one" --evil -- /usr/bin/true; then exit 1; fi

# Missing hide path refuses to start.
mkdir -p "$private/empty-proj"
if "$launcher" -p "$private/empty-proj" --hide "$private/empty-proj/.env" -- /usr/bin/true; then exit 1; fi
err=$("$launcher" -p "$private/empty-proj" --hide "$private/empty-proj/.env" -- /usr/bin/true 2>&1 || true)
[[ "$err" == *'--hide: not found'* ]]
test ! -e "$private/empty-proj/.env"

printf 'Mount checks passed.\n'
