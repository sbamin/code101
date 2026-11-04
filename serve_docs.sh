#!/bin/bash

DOCDIR="$HOME"/sync/dbsa/acad/scripts/github/webpages/live/code101/web

if [[ ! -d "$DOCDIR" || ! -x "$DOCDIR" ]]; then
	echo -e "\nERROR: DOCDIR does not exists or not accesible at $DOCDIR\n" >&2
	exit 1
fi

mkdocs() { pixi run --manifest-path "$HOME"/.config/pixi-global/pixi.toml -e sitebuilder mkdocs "$@"; }

cd "$DOCDIR" && echo -e "\nWorkdir is $DOCDIR\n"
mkdocs -q serve -a localhost:4000
