# agent-sandbox

Filesystem isolation for AI coding agents. It runs commands without exposing home files such as documents,
projects, and secrets. Built on Bubblewrap, agent-sandbox provides a shared launcher with per-agent wrappers 
that define their own filesystem access.

## Why

AI coding agents run arbitrary commands. Your home holds secrets, keys and unrelated projects. 
agent-sandbox gives each agent only the project and paths you mount, nothing else.

## Requirements

Install Bubblewrap on Linux:

**Arch Linux:**

```sh
sudo pacman -S bubblewrap
```

**Debian / Ubuntu:**

```sh
sudo apt update
sudo apt install bubblewrap
```

Check that it is available:

```sh
bwrap --version
```

The script assumes a merged /usr layout. Bubblewrap needs unprivileged user namespaces to be enabled.

macOS and Windows are not supported.

## Install

Clone the repo into `~/.local/share/agent-sandbox`. Then:

```sh
mkdir -p "$HOME/.local/share" "$HOME/.local/bin"
ln -s "$HOME/.local/share/agent-sandbox/agent-sandbox" "$HOME/.local/bin/agent-sandbox"
"$HOME/.local/bin/agent-sandbox" --help
```

If `~/.local/bin` is not already in your PATH, add this line to `~/.bashrc`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

To update, go to the cloned repository and pull the latest changes:

```sh
cd "$HOME/.local/share/agent-sandbox"
git pull --ff-only origin main
```

## Tests

```sh
bash tests/launcher.sh   # syntax, argument passing, host mode
bash tests/mounts.sh     # actual read-only and read-write mounts
```

```sh
shellcheck agent-sandbox tests/*.sh
shfmt -i 4 -d agent-sandbox tests/*.sh   # check only
shfmt -i 4 -w agent-sandbox tests/*.sh   # format in place
```

## Agent wrappers

Create a wrapper for each agent you use (`opencode-sandbox`, `claude-sandbox`, etc.) to keep its mounts in one place.

For OpenCode, create ~/.local/bin/opencode-sandbox with the following contents. 
Adjust the paths to match your installation:

```bash
#!/usr/bin/env bash
exec "$HOME/.local/bin/agent-sandbox" \
  --command /opt/opencode \
  --ro "$HOME/.opencode/bin/opencode" /opt/opencode \
  --ro "$HOME/.config/opencode" \
  --rw "$HOME/.local/share/opencode" \
  --rw "$HOME/.cache/opencode" \
  --rw "$HOME/.local/state/opencode" \
  "$@"
```

In `--host` mode, a command mounted at a different destination runs from its original path on the host.

Make the wrapper executable:

```sh
chmod +x "$HOME/.local/bin/opencode-sandbox"
```

Add the shortcut to `~/.bashrc`:

```bash
opencode() { "$HOME/.local/bin/opencode-sandbox" "$@"; }
```

Use the same pattern for other agents, with their own wrapper files and shortcuts. 
Only OpenCode has been tried so far; the others need their own mounts and testing.

Two more options, for binaries outside `/usr/bin`:

```bash
--ro "$HOME/.cargo/bin/kanban-mcp"   # mount the file...
--path "$HOME/.cargo/bin"            # ...and put its dir on PATH
```

`--ro` and `--rw` take an optional second path to mount somewhere else
inside (`--rw SRC DST`), for example to run a binary from `/opt`.

## Usage

```sh
opencode                                # Chat without mounting a project
opencode -p                             # Work on the current directory
opencode -p "$HOME/Project"             # Work on another directory
opencode -p --ro "$HOME/Downloads"      # Read another directory
opencode -p --rw "$HOME/Documents"      # Read and write another directory
opencode -p --hide "$HOME/Project/.env" # Work but keep secrets hidden
opencode --host                         # Run without the sandbox
opencode --help                         # Show wrapper and OpenCode help
```

### Mounts

`--ro` and `--rw` mount paths read-only or read-write. Both accept a
comma-separated list and can be repeated:

`--ro "$HOME/Downloads,$HOME/Music"`

### Hiding secrets

`--hide` (or `--exclude`) masks a file or directory inside the sandbox so
the agent can neither read nor write through it. Useful for `.env` files
inside an otherwise mounted project.

### Strict paths

Every path must exist. A missing path aborts before starting anything
with a `--flag: not found: path` error.

### Project

`-p` (or `--project`) mounts a project read-write and defaults to the
current directory when omitted.

### Inspection

`--dry-run` prints the `bwrap` command the sandbox would run without
running it. Useful to audit what the agent would see.

## MCP examples

### Codebase Memory MCP

Mount its executable to run the MCP and its OpenCode plugin:

```bash
--ro "$HOME/.local/bin/codebase-memory-mcp"
```

Without a cache mount, its index is temporary. To reuse the host cache, add:

```bash
--rw "$HOME/.cache/codebase-memory-mcp"
```

### Kanban MCP

Mount its executable and boards. The sandbox fixes PATH to `/usr/bin:/bin`,
so `kanban-mcp` is only found by bare name with `--path`:

```bash
--ro "$HOME/.cargo/bin/kanban-mcp"
--path "$HOME/.cargo/bin"
--rw "$HOME/.local/share/kanban"
```

Executable paths and data locations vary by installation.

## License

MIT
