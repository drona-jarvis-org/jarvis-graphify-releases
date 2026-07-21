# jarvis-graphify

> **Enriched code knowledge graph** — point it at any codebase and get an interactive graph where every node has a working summary, every library has a threat profile, and every sensitive file is flagged.

---

## Install — one command

**macOS / Linux:**
```bash
curl -fsSL https://raw.githubusercontent.com/drona-jarvis-org/jarvis-graphify-releases/main/install.sh | bash
```

**Windows (PowerShell):**
```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/drona-jarvis-org/jarvis-graphify-releases/main/install.ps1" -OutFile install.ps1; .\install.ps1
```

After install, restart your terminal then verify:
```bash
jarvis-graphify --version
```

---

## What it does

```
Your codebase
     │
     ▼
jarvis-graphify .
     │
     ├── graph.html             ← interactive graph (open in any browser)
     ├── graph.json             ← full graph data with summaries
     └── graph_understanding.md ← text report of every entity
```

Every node in the graph gets a **working summary** written by your LLM:

| Node type | Summary sections |
|-----------|-----------------|
| File | WHAT · WHY · IMPACT · EXTEND |
| Class | WHAT · WHY · IMPACT · EXTEND |
| Function / Method | WHAT · WHY · IMPACT · EXTEND |
| Library / Import | WHAT · WHY · IMPACT · DECAY · VULNERABILITIES |

Plus:
- **⭐ Entry point detection** — `main()`, HTTP routes, CLI commands, `__main__` blocks
- **🔴 Sensitive file detection** — credentials, tokens, PII, connection strings flagged red
- **Traversal paths** — click any entry point and walk the graph node-by-node with breadcrumb trail
- **Zero cloud dependency option** — works fully offline with a local Ollama model

---

## Quick start

### 1 · Install

```bash
curl -fsSL https://raw.githubusercontent.com/drona-jarvis-org/jarvis-graphify-releases/main/install.sh | bash
source ~/.zshrc
```

### 2 · Configure — mode + backend (the installer offers this automatically)

```bash
cd /path/to/your-project
jarvis-graphify configure        # setup is an alias of the same flow
```

**Step 1 — pick a mode:**

| # | Mode | Who does the enrichment | Data privacy |
|---|------|------------------------|--------------|
| 1 | `custom_intelligence` | Your own model (step 2 below) | Code stays with the endpoint you control |
| 2 | `claude` | Claude Code — one smart `/jarvis-graphify-scan` skill in `.claude/skills/` (full scan first time, incremental after — only files modified since the last scan), enriched with **Claude's own model** | ⚠ **sensitive project data goes to Anthropic** |
| 3 | `cursor` | Cursor's AI — rules in `.cursor/rules/` | ⚠ **sensitive project data goes to Cursor** |
| 4 | `codex` | Codex — workflow in `AGENTS.md` | ⚠ **sensitive project data goes to OpenAI** |

> **AI modes use the tool's own logged-in model** — nothing from settings, no API key.
> Bonus: if the tool's headless CLI is installed (`claude`, `cursor-agent`, `codex`),
> a plain `jarvis-graphify .` / `jarvis-graphify update .` enriches automatically with
> that model (batched ~15 nodes per call). Without the CLI, run the skill inside the tool.

**Step 2 — for `custom_intelligence`, pick a backend:**

| Backend | You're asked for | Notes |
|---------|-----------------|-------|
| `jarvis_server` | url + key | Jarvis server hosts the model; same url + key also become the scan push target |
| `litellm` | url + key + model | Any model hosted OpenAI-style, local or remote (vLLM, LM Studio, LiteLLM proxy, OpenRouter, Azure…) |
| `ollama` | url + key (optional) + model | Local Ollama server |

Non-interactive (flags do the same flow):

```bash
jarvis-graphify configure --mode jarvis_server --url https://jarvis.example.com --key JRV-KEY-123
jarvis-graphify configure --mode litellm --url http://127.0.0.1:8000/v1 --key sk-local --model_name llama-3.1-8b
jarvis-graphify configure --mode ollama --url http://127.0.0.1:11434 --key '' --model_name qwen3:4b
jarvis-graphify configure --mode claude --yes
```

Answers are written to `jarvis-graphify-in/settings.json` (hand-editable, see below).

### 3 · Run

```bash
jarvis-graphify .
open jarvis-graphify-out/graph.html     # macOS
xdg-open jarvis-graphify-out/graph.html # Linux
```

---

## LLM backends

Set `"backend"` in `jarvis-graphify-in/settings.json` to one of:
`jarvis_server` · `ollama` · `litellm` · `bedrock` — or just run `jarvis-graphify configure`.

---

### Option 0 — Jarvis server (url + key)

Your Jarvis server hosts the model (OpenAI-compatible endpoint at
`<url>/api/v1/llm/chat/completions`) — the server picks the model. The same
url + key are saved as the **push target**, so scan results upload there too.

```json
{
  "llm": {
    "backend": "jarvis_server",
    "jarvis_server": {
      "url": "https://jarvis.example.com",
      "api_key": "JRV-KEY-123",
      "model": "",
      "ssl_verify": true
    }
  }
}
```

---

### Option A — Ollama (local, no API key, fully offline)

Ollama runs models locally on your machine. Supports **any model available via Ollama** —
qwen3, llama3, mistral, phi3, gemma2, deepseek, and more.

```bash
# Install Ollama (macOS)
brew install ollama

# Pull a model and start the server
ollama pull qwen3:4b
ollama serve
```

```json
{
  "llm": {
    "backend": "ollama",
    "ollama": {
      "base_url": "http://127.0.0.1:11434",
      "model": "qwen3:4b"
    }
  }
}
```

> List available models: `ollama list`  
> Hosted Ollama server with TLS? Add `"ssl_verify": false` for self-signed certs.

---

### Option B — LiteLLM / OpenAI-compatible APIs

Works with **any endpoint that speaks OpenAI's `/chat/completions` format**:

| Platform | Notes |
|----------|-------|
| **LiteLLM proxy** | Self-hosted unified gateway to 100+ providers |
| **vLLM** | Self-hosted high-throughput inference server |
| **TensorRT-LLM** | NVIDIA GPU-optimised inference |
| **Custom Python** | Any FastAPI/Flask server with OpenAI-style API |
| **OpenRouter** | `https://openrouter.ai/api/v1` — 100+ models, one key |
| **Azure OpenAI** | Your Azure deployment endpoint |
| **Groq, Together AI, Anyscale** | Drop in their base_url + api_key |

```json
{
  "llm": {
    "backend": "litellm",
    "litellm": {
      "base_url": "https://your-litellm-server.example.com",
      "model": "gpt-4o",
      "api_key": "sk-YOUR-KEY-HERE",
      "ssl_verify": false
    }
  }
}
```

**Or read the key from an environment variable** (keeps secrets out of the file):
```json
{
  "llm": {
    "backend": "litellm",
    "litellm": {
      "base_url": "https://openrouter.ai/api/v1",
      "model": "anthropic/claude-3-haiku",
      "api_key_env": "OPENROUTER_API_KEY"
    }
  }
}
```
```bash
export OPENROUTER_API_KEY="sk-or-..."
```

> `"ssl_verify": false` — use for corporate/self-signed certificates.

---

### Option C — AWS Bedrock

Access Claude, Llama, Mistral, Titan and other foundation models via **AWS managed infrastructure**.
No model hosting needed — pay per token.

**Available models (examples):**

| Model | model_id |
|-------|---------|
| Claude 3.5 Haiku | `anthropic.claude-3-5-haiku-20241022-v1:0` |
| Claude 3.5 Sonnet | `anthropic.claude-3-5-sonnet-20241022-v2:0` |
| Llama 3.3 70B | `meta.llama3-3-70b-instruct-v1:0` |
| Mistral Large | `mistral.mistral-large-2402-v1:0` |
| Amazon Titan Premier | `amazon.titan-text-premier-v1:0` |

```json
{
  "llm": {
    "backend": "bedrock",
    "bedrock": {
      "region": "us-east-1",
      "model_id": "anthropic.claude-3-5-haiku-20241022-v1:0",
      "aws_access_key_id": "AKIAIOSFODNN7EXAMPLE",
      "aws_secret_access_key": "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
    }
  }
}
```

**Or use environment variables (recommended — no keys in files):**
```bash
export AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
export AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
export AWS_DEFAULT_REGION=us-east-1
```
```json
{
  "llm": {
    "backend": "bedrock",
    "bedrock": {
      "region": "us-east-1",
      "model_id": "anthropic.claude-3-5-haiku-20241022-v1:0"
    }
  }
}
```

**Credential resolution order:**
1. Explicit keys in `settings.json`
2. `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` / `AWS_SESSION_TOKEN` env vars
3. `~/.aws/credentials` profile (`aws configure`)
4. IAM role attached to EC2 / ECS / Lambda (no config needed)

**Install boto3** (required for Bedrock, not bundled):
```bash
pip install boto3
# or inside the jarvis-graphify venv:
~/.jarvis-graphify/venv/bin/pip install boto3
```

> Enable the model in your AWS account first:  
> AWS Console → Bedrock → Model access → Request access

---

## All commands

**Complete list (v1.2.0):**

| Command | What it does |
|---------|-------------|
| `jarvis-graphify configure` (alias `setup`) | pick mode + backend + url/key/model; `--global`, `--embedding-model` |
| `jarvis-graphify .` | full scan + enrich (default). Flags: `--no-enrich --offline --no-integrate -v --out` |
| `jarvis-graphify update .` | incremental — only changed files |
| `jarvis-graphify render .` | finalise AI-filled graph.json -> version, metadata, push |
| `jarvis-graphify serve-mcp .` | MCP server (10 tools) for Claude Code / Cursor / Codex |
| `jarvis-graphify ask "..."` | answer a question from the graph, no source reading |
| `jarvis-graphify find "..."` | semantic/keyword symbol search (JSON) |
| `jarvis-graphify assess "..." --steps a,b` | drift check before coding (graph + LLM) |
| `jarvis-graphify draft "..." --targets X` | grounded, verified code generation via your custom model |
| `jarvis-graphify embed .` | build semantic vectors from existing graph.json |
| `jarvis-graphify render-html .` | rebuild only graph.html (offline, no LLM) |
| `jarvis-graphify server-config ...` | set Jarvis push target (`--show` / `--clear`) |
| `jarvis-graphify integrate` | (re)write Cursor/Claude/Codex rules + MCP registration |

Every command, every flag, with examples.

### `jarvis-graphify configure` — guided config (also runs at install time)

```bash
jarvis-graphify configure                # interactive: mode → backend → url/key/model
jarvis-graphify --configure              # flag form — identical
jarvis-graphify setup                    # alias of the same flow

# custom_intelligence backends, non-interactive:
jarvis-graphify configure --mode jarvis_server --url https://jarvis.example.com --key JRV-KEY-123
jarvis-graphify configure --mode litellm --url http://127.0.0.1:8000/v1 --key sk-local --model_name llama-3.1-8b
jarvis-graphify configure --mode ollama --url http://127.0.0.1:11434 --key '' --model_name qwen3:4b

# AI-assisted modes (assistant performs the scan — caution + confirmation):
jarvis-graphify configure --mode claude --yes
jarvis-graphify configure --mode cursor --yes
jarvis-graphify configure --mode codex  --yes

jarvis-graphify configure --force        # overwrite existing settings.json
```

| Flag | Meaning |
|------|---------|
| `--mode` | `custom_intelligence` \| `claude` \| `cursor` \| `codex` — or a backend name (`jarvis_server`/`litellm`/`ollama`) as custom shorthand |
| `--backend` | backend for custom mode |
| `--url` | backend / Jarvis server URL |
| `--key` (alias `--api-key`) | API key — `''` for none (e.g. local Ollama) |
| `--model_name` (alias `--model`) | model name (litellm / ollama; optional for jarvis_server) |
| `--yes` | accept the sensitive-data caution for AI modes |
| `--force` | overwrite existing config |

### `jarvis-graphify [scan]` — full scan (default command)

```bash
jarvis-graphify .                        # full scan — current directory
jarvis-graphify /path/to/project         # scan any directory
jarvis-graphify scan .                   # explicit subcommand form
jarvis-graphify . --no-enrich            # structure + secrets only, no LLM (AI-mode step 1)
jarvis-graphify . --no-integrate         # skip Cursor/Claude/Codex rule injection
jarvis-graphify . --out /tmp/my-graph    # custom output directory
jarvis-graphify . -v                     # verbose — show each node as enriched
```

Each enriched scan bumps the version (`<project>_vN`), writes `graph.json` /
`graph.html` / `graph_understanding.md` / `feedback.md`, records metadata
(project uuid, datetime, machine user, machine IP, path) in `project_meta.json`,
snapshots to `history/<project>_vN/`, and pushes to the Jarvis server when configured.

### `jarvis-graphify update` — incremental

```bash
jarvis-graphify update                   # re-enrich only new/modified files (fast)
jarvis-graphify update /path/to/project  # update a specific project
jarvis-graphify update --no-enrich       # reuse summaries; leave changed nodes empty (AI modes)
jarvis-graphify update --force-libraries # also re-enrich library summaries
jarvis-graphify update -v                # verbose
```

### `jarvis-graphify render` — finalise a scan from graph.json (AI modes)

```bash
jarvis-graphify render .                 # re-render html/md/feedback, assign next
                                         # version, record metadata, push to server
```

### `jarvis-graphify server-config` — Jarvis server push target

```bash
jarvis-graphify server-config --url https://jarvis.example.com --api-key JRV-KEY-123
jarvis-graphify server-config --no-ssl-verify --url https://jarvis.internal --api-key K
jarvis-graphify server-config --show     # current config (key masked)
jarvis-graphify server-config --clear    # stop pushing
```

Stored at `~/.jarvis-graphify/server.json` (chmod 600). Every scan / update /
render then uploads metadata + all output files to a per-project folder on the
server (keyed by project uuid).

### `jarvis-graphify integrate` — (re)write AI-tool rules

```bash
jarvis-graphify integrate                # all: Cursor + Claude Code + Codex
jarvis-graphify integrate --cursor       # Cursor only  → .cursor/rules/jarvis-graphify.mdc
jarvis-graphify integrate --claude       # Claude Code  → CLAUDE.md
jarvis-graphify integrate --codex        # Codex / OpenAI Agents → AGENTS.md
```

### Misc

```bash
jarvis-graphify --version
jarvis-graphify --help
jarvis-graphify <command> --help
```

---

## Incremental update (`jarvis-graphify update`)

After the first full scan, use `update` instead of rescanning everything when you add or modify files:

```bash
jarvis-graphify update                   # re-enrich only changed files
jarvis-graphify update --force-libraries # also refresh library summaries
jarvis-graphify update -v                # verbose — show each updated node
```

| File state | What happens |
|-----------|-------------|
| **Modified** (mtime > graph.json) | All nodes in this file are re-enriched |
| **New file** | Scanned and enriched from scratch |
| **Deleted file** | Its nodes are removed from the graph |
| **Unchanged file** | Existing summaries reused — no LLM call |
| **Library / import** | Summary always reused (use `--force-libraries` to refresh) |

> First run with `update`: if no `graph.json` exists yet, it performs a full scan automatically.

---

## Exclusions

Control what gets LLM summaries and what gets sensitivity scanning via the `exclude`
section in `jarvis-graphify-in/settings.json` (created by `jarvis-graphify setup`):

```json
{
  "exclude": {
    "libraries": ["os", "sys", "re", "json", "typing", "abc"],
    "methods":   ["__init__", "__str__", "__repr__", "__eq__", "__hash__"],
    "enrich_files":      [],
    "sensitivity_files": ["tests/**", "**/*.example"]
  }
}
```

| Key | Effect |
|-----|--------|
| `libraries` | Skip LLM enrichment for these library/import node names |
| `methods` | Skip LLM enrichment for methods/functions with these bare names |
| `enrich_files` | Glob patterns — skip all enrichment for nodes in matching files |
| `sensitivity_files` | Glob patterns — skip sensitive-data scanning for matching files |

---

## IDE deep-integration (`jarvis-graphify integrate`)

After generating the graph, run `integrate` to automatically wire the knowledge graph
into your AI coding tools:

```bash
cd /path/to/your-project
jarvis-graphify .           # generate the graph
jarvis-graphify integrate   # create IDE rules for all supported tools
```

This creates project-level rules that instruct each AI tool to **always consult the
pre-computed knowledge graph before reading raw source files**, reducing token usage
and giving the AI richer context on every query.

### What gets created

| Tool | File created / updated | Effect |
|------|----------------------|--------|
| **Cursor** | `.cursor/rules/jarvis-graphify.mdc` | `alwaysApply: true` rule — injected into every Cursor AI request |
| **Claude Code** | `CLAUDE.md` | `<!-- jarvis-graphify:start/end -->` section — read by Claude Code on every session |
| **Codex / OpenAI Agents** | `AGENTS.md` | Standard Codex agents knowledge file |

### How the AI uses it

Each generated rule instructs the AI:

1. **Project questions** → read `jarvis-graphify-out/graph_understanding.md` first (pre-summarised, lowest token cost)
2. **Node-level detail** → look up in `jarvis-graphify-out/graph.json` by `id` or `label`
3. **Raw source** → only when implementation specifics aren't covered by the graph
4. **Library questions** → check node `summary.DECAY` + `summary.VULNERABILITIES` in graph.json

The rules also embed live stats (node count, edge count, entry points, sensitive files)
pulled from `graph.json` so the AI knows the graph exists and what it contains.

### Keeping it up to date

Re-run both commands after significant code changes:

```bash
jarvis-graphify .           # regenerate graph
jarvis-graphify integrate   # refresh IDE rules with updated stats
```

The `integrate` command is idempotent — it replaces the existing section rather than appending.

---

## Using the graph

Open `jarvis-graphify-out/graph.html` in any browser — no internet required.

| Action | Result |
|--------|--------|
| **Click a node** | WHAT / WHY / IMPACT / EXTEND in the sidebar |
| **Click a library** | WHAT / WHY / IMPACT / DECAY / VULNERABILITIES |
| **Click a 🔴 red node** | Sensitive findings (category + line number) |
| **Entry point chips ⭐** | Jump to any entry point |
| **Next nodes panel** | All outgoing connections — click to traverse |
| **Breadcrumb trail** | Navigate back through your path |
| **Search box** | Find and highlight any node |
| Scroll / Drag | Zoom / Pan |

### Node colours

| Colour | Meaning |
|--------|---------|
| ⭐ Gold star | Entry point |
| 🔵 Blue box | Source file |
| 🟠 Orange ellipse | Class |
| 🟢 Green dot | Function |
| 🩵 Teal dot | Method |
| 🔴 Red diamond | Library / import |
| 🔴 Red (any shape) | Sensitive file — credentials / PII / secrets detected |

---

## Troubleshooting

**`jarvis-graphify: command not found`**
```bash
export PATH="$HOME/.local/bin:$PATH"
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
```

**`No LLM config found`**  
Run `jarvis-graphify setup`, then edit `jarvis-graphify-in/settings.json`.

**`SSL: CERTIFICATE_VERIFY_FAILED`**  
Add `"ssl_verify": false` to the `ollama` or `litellm` block.

**`Connection refused` (Ollama)**  
Start the server: `ollama serve`

**`boto3 is required for AWS Bedrock`**  
```bash
~/.jarvis-graphify/venv/bin/pip install boto3
```

**`Could not connect to the endpoint URL` (Bedrock)**  
Check your `region` and that the model is enabled in AWS Console → Bedrock → Model access.

**LLM returns empty responses**  
Run `jarvis-graphify . -v` to see which nodes fail. Try a smaller/faster model or check rate limits.

---

## How it works

```
scanner.py     → AST-based code scan (Python) + regex (JS/TS/Java/Go)
                 detects: files, classes, functions, methods, imports
                 flags:   entry points, sensitive data

enricher.py    → sends each node to your LLM for a structured summary
                 code nodes:    WHAT / WHY / IMPACT / EXTEND
                 library nodes: WHAT / WHY / IMPACT / DECAY / VULNERABILITIES

graph_builder  → assembles nodes + edges, BFS traversal from each entry point

renderer.py    → graph.html (vis.js), graph.json, graph_understanding.md
```

---

## License

MIT
