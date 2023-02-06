#!/usr/bin/env bash

venv="$HOME/.emacs.d/py3-env"

python3 -m venv "$venv"
source "$venv/bin/activate"
pip install -U pip wheel
pip install -e "$HOME/.emacs.d/openaiwrappers"

# use nh/venv-setup from within emacs to install language server, etc

