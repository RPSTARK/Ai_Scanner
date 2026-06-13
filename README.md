# AI Security Orchestrator

A plug-and-play orchestrator for LLM/AI red-teaming tools. Wraps multiple
security scanners ("adapters") behind one dashboard, consolidates and
cross-validates their findings, and lets you configure everything -
API keys, scan scope, adapters, targets - from the web UI. No env vars,
no config files to hand-edit after install.

## Quick start (one command)

```bash
bash install.sh
```

This installs Python dependencies and starts the server at
**http://localhost:8000**. Open that URL - everything else (adding
adapters, setting API keys, saving targets, running scans) happens in
the browser.

To run again later:
```bash
cd backend && python3 -m uvicorn main:app --port 8000
```

## What's included out of the box

- **custom_probes** - our curated probe library (14 probes across
  system-prompt extraction, data exfiltration, jailbreaks, tool abuse,
  prompt injection). No install required. Optionally configure an
  Anthropic API key in its "Configure" panel for LLM-graded results
  (falls back to a keyword-based judge if not set).
- **garak** (NVIDIA) - installable from the Marketplace tab with one
  click. Configurable probe modules and scan profile.
- **mcp_scan** and **modelscan** - available in the "Add Adapter" tab
  catalog; one click adds them to your marketplace, then install +
  configure like any other adapter.

## Demo target

A small Flask app with a deliberately vulnerable system prompt (an
embedded fake API key, fake order-lookup tool, etc.) is included so you
can test the orchestrator immediately:

```bash
python3 mock_target.py        # no API key needed, runs on :5000
# or
python3 demo_target.py         # real Claude-backed version (needs ANTHROPIC_API_KEY)
```

Then in the "run scan" tab, set the chat endpoint to
`http://localhost:5000/chat` and run `custom_probes`.

## How everything fits together

```
ai-orchestrator/
  install.sh           <- one-command setup
  backend/
    main.py             FastAPI app + API routes
    db.py               SQLite persistence (targets, scans, adapter configs)
    registry.py          adapter discovery, install, config
    catalog.py            "Add Adapter" catalog -> writes new adapters/<id>/
    consolidate.py        dedup + cross-validation of findings
    report_md.py          markdown report generator
    orchestrator.db        created on first run (SQLite)
  adapters/
    <adapter_id>/
      manifest.yaml        metadata, install type, config_schema
      adapter.py            run_scan(target_config, progress_cb) -> [Finding,...]
  frontend/
    index.html             single-page UI: dashboard, marketplace,
                            add adapter, run scan, results
```

## Adding your own adapter

From the "Add Adapter" tab, paste a GitHub URL pointing to a folder with
a `manifest.yaml` + `adapter.py` (matching the structure above), or for
adapters already in the built-in catalog, just click "+ add". Once
added it shows up in the Marketplace like any other adapter - install,
configure, and select it for scans.

A minimal `manifest.yaml`:

```yaml
id: my_adapter
name: "My Adapter"
description: "What it does"
category: llm_redteam
install:
  type: pip          # or "none" / "binary" / "git"
  package: my-pip-package
config_schema:        # optional - drives the Configure modal
  - key: some_api_key
    label: "Some API Key"
    type: password
    required: false
input_requires: [chat_endpoint]
output_categories: [jailbreak]
```

And `adapter.py` must define:

```python
def run_scan(target_config: dict, progress_cb=None) -> list[dict]:
    # return a list of Finding dicts (see backend/schema.py)
    ...
```

## Notes

- All persistent state lives in `backend/orchestrator.db` (SQLite) -
  delete it to reset everything.
- Scans run in a background thread; poll `GET /api/scan/{id}` for
  progress and results.
- Reports are downloadable as Markdown from the Results tab.
