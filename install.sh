#!/usr/bin/env bash
#
# AI Security Orchestrator - one-command setup
#
# Usage:
#   bash install.sh
#
# This installs Python dependencies and starts the orchestrator at
# http://localhost:8000. All further configuration (API keys, adapter
# installs, targets, scan settings) is done through that web UI - no
# further commands needed.

set -e

echo "[*] AI Security Orchestrator - setup"
echo

if ! command -v python3 &> /dev/null; then
    echo "[!!] python3 is required but not found. Install Python 3.10+ first."
    exit 1
fi

echo "[*] Installing dependencies..."
python3 -m pip install --break-system-packages -q \
    fastapi uvicorn pyyaml requests anthropic flask

echo "[*] Dependencies installed."
echo
echo "[*] Starting orchestrator at http://localhost:8000"
echo "[*] Open that URL in your browser. All setup from here is via the UI."
echo "[*] Press Ctrl+C to stop."
echo

cd "$(dirname "$0")/backend"
python3 -m uvicorn main:app --host 0.0.0.0 --port 8000
