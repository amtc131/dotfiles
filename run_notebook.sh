#!/usr/bin/env bash
set -euo pipefail

# --- Config ---
VENV_DIR="$HOME/my-jupyter-env"
LOG_DIR="$HOME/.config/notebook"
LOG_FILE="$LOG_DIR/jupyter.log"
PORT="${JUPYTER_PORT:-8888}"
IP="127.0.0.1"

ICON_ON=" jupyter "   
ICON_OFF=" jupyter "

running=0
if pgrep -f "jupyter-notebook" >/dev/null 2>&1; then
  running=1
fi

if [[ "${BLOCK_BUTTON:-0}" == "0" ]]; then
  if [[ $running -eq 1 ]]; then
    echo "$ICON_ON jupyter:$PORT"
    echo "jupyter"
    echo "#39ff14"
  else
    echo "$ICON_OFF"
    echo "off"
    echo "#b0b5bd"
  fi
fi

case "${BLOCK_BUTTON:-}" in
  1)
      mkdir -p "$LOG_DIR"

      if [[ ! -d "$VENV_DIR" ]]; then
        python3 -m venv "$VENV_DIR"
      fi

      source "$VENV_DIR/bin/activate"

      if ! pip show notebook >/dev/null 2>&1; then
        python -m pip install --upgrade pip >/dev/null 2>&1 || true
        pip install notebook >/dev/null 2>&1
      fi

      if pgrep -f "jupyter-notebook" >/dev/null 2>&1; then
        exit 0
      fi

      nohup jupyter-notebook \
        --no-browser \
        --ip="$IP" \
        --port="$PORT" \
        >"$LOG_FILE" 2>&1 &

      ;;
  3) 
      pkill -f "jupyter-notebook" >/dev/null 2>&1 || true
      sleep 0.3
      pkill -9 -f "jupyter-notebook" >/dev/null 2>&1 || true
      ;;
esac
