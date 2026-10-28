#!/usr/bin/env bash
# Check the Model and refresh the pictures in docs/img.
#
# Uses the SysML v2 Viewer's CLI. Set SYSML_VIEWER to its binary, or
# VIEWER_REPO to a checkout of the viewer (default ~/git/sysmlv2_egui),
# which is built on demand.
set -uo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
repo="${VIEWER_REPO:-$HOME/git/sysmlv2_egui}"

if [[ -n "${SYSML_VIEWER:-}" ]]; then
    viewer=("$SYSML_VIEWER")
else
    viewer=(cargo run -q --release --manifest-path "$repo/Cargo.toml" -p viewer-cli --)
fi

"${viewer[@]}" export "$here" --all --out-dir "$here/docs/img" || exit $?
"${viewer[@]}" check "$here"
