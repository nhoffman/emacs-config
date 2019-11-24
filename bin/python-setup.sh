#!/usr/bin/env bash

venv="~/.emacs.d/py3-env"

python3 -m venv "$venv"
source "$venv/bin/activate"
pip install -U pip
pip install -U flake8
