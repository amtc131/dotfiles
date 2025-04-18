#!/bin/bash

# Ruta del entorno virtual
VENV_DIR="$HOME/.config/venvs/notebook"

# Crear entorno si no existe
if [ ! -d "$VENV_DIR" ]; then
  echo "Creando entorno virtual en $VENV_DIR..."
  python3 -m venv "$VENV_DIR"
fi

# Activar entorno virtual
echo "Activando entorno virtual..."
source "$VENV_DIR/bin/activate"

# Instalar notebook si no está instalado
if ! pip show notebook > /dev/null 2>&1; then
  echo "Instalando Jupyter Notebook..."
  pip install --upgrade pip
  pip install notebook
fi

# Verificar si ya está corriendo
if pgrep -f "jupyter-notebook" > /dev/null; then
  echo "Jupyter Notebook ya está en ejecución."
  exit 0
fi

# Lanzar Jupyter Notebook (abre navegador por defecto)
echo "Iniciando Jupyter Notebook..."
jupyter-notebook > "$HOME/.config/notebook/jupyter.log" 2>&1 &

