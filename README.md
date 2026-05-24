# jarvis-graphify

> **Enriched code knowledge graph** — point it at any codebase and get an interactive graph where every node has a working summary, every library has a threat profile, and every sensitive file is flagged.

---

## Install — one command

**macOS / Linux:**
```bash
curl -fsSL https://raw.githubusercontent.com/dronaprod/jarvis-graphify/main/install.sh | bash
```

**Windows (PowerShell):**
```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/dronaprod/jarvis-graphify/main/install.ps1" -OutFile install.ps1; .\install.ps1
```

> No Python required — the installer downloads a self-contained binary for your platform.

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

Every node gets a **working summary** written by your LLM:

| Node type | Summary sections |
|-----------|-----------------|
| File | WHAT · WHY · IMPACT · EXTEND |
| Class | WHAT · WHY · IMPACT · EXTEND |
| Function / Method | WHAT · WHY · IMPACT · EXTEND |
| Library / Import | WHAT · WHY · IMPACT · DECAY · VULNERABILITIES |

**Also:**
- ⭐ **Entry point detection** — `main()`, HTTP routes, CLI commands, `__main__` blocks
- 🔴 **Sensitive file detection** — credentials, tokens, PII, connection strings flagged red
- **Traversal paths** — walk the graph node-by-node from any entry point
- **Works fully offline** — use a local Ollama model, no cloud needed

---

## Quick start

```bash
# 1. Install
curl -fsSL https://raw.githubusercontent.com/dronaprod/jarvis-graphify/main/install.sh | bash
source ~/.zshrc

# 2. Create config in your project
cd /path/to/your-project
jarvis-graphify setup

# 3. Edit jarvis-graphify-in/settings.json  (see Configure below)

# 4. Run
jarvis-graphify .

# 5. Open the graph
open jarvis-graphify-out/graph.html        # macOS
xdg-open jarvis-graphify-out/graph.html   # Linux
```

---

## Configure your LLM

`jarvis-graphify setup` creates `jarvis-graphify-in/settings.json` in your project. Edit it:

### Option A — Ollama (local, no API key, fully offline)

```bash
# macOS
brew install ollama
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

### Option B — LiteLLM / any OpenAI-compatible API

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

> `"ssl_verify": false` — use this for corporate / self-signed certificates.

---

## All commands

```bash
jarvis-graphify .                        # full scan — current directory
jarvis-graphify /path/to/project         # scan any directory
jarvis-graphify . --no-enrich            # structure + sensitive detection only (no LLM calls)
jarvis-graphify . --out /tmp/my-graph    # custom output directory
jarvis-graphify . -v                     # verbose — show each node as it's enriched

jarvis-graphify scan .                   # explicit subcommand form
jarvis-graphify setup                    # create config in current directory
jarvis-graphify setup --force            # overwrite existing config

jarvis-graphify --version
jarvis-graphify --help
```

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
| 🔴 Red (any shape) | **Sensitive file** — hardcoded credentials / PII / secrets detected |

---

## Windows

Open **PowerShell** and run:

```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/dronaprod/jarvis-graphify/main/install.ps1" -OutFile install.ps1

# If prompted about execution policy:
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned

.\install.ps1            # user install (no admin needed)
.\install.ps1 -Global    # system-wide (requires Administrator)
```

Restart PowerShell after install, then verify:

```powershell
jarvis-graphify --version
```

---

## Updating

Just re-run the install command — it always fetches the latest release:

```bash
curl -fsSL https://raw.githubusercontent.com/dronaprod/jarvis-graphify/main/install.sh | bash
```

---

## Troubleshooting

**`jarvis-graphify: command not found`**
```bash
export PATH="$HOME/.local/bin:$PATH"
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
```

**`No LLM config found`**
Run `jarvis-graphify setup` in your project, then edit `jarvis-graphify-in/settings.json`.

**`SSL: CERTIFICATE_VERIFY_FAILED`**
Set `"ssl_verify": false` under the `litellm` block.

**`Connection refused`**
Ollama isn't running. Start it: `ollama serve`.

**LLM returns empty responses**
Model is overloaded. Run `jarvis-graphify . -v` to see which nodes fail, or use a smaller model.

---

## License

MIT
