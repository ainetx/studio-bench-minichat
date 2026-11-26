#!/usr/bin/env bash
#
# Run the mini-chat e2e suite as the B9-minichat benchmark grades it.
#
# Usage: ./testing/e2e/benchmark/run.sh [extra pytest args]

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
E2E="$ROOT/testing/e2e"
HERE="$E2E/benchmark"

# The features come from suites/mini_chat/e2e.yaml.
cd "$ROOT"
cargo build --bin cf-gears-example-server --no-default-features \
    --features mini-chat,static-authn,static-authz,single-tenant,static-credstore

# pytest makes node ids relative to its rootdir testing/e2e (pytest.ini), so the path starts at suites/.
DESELECT=()
while IFS= read -r line; do
    case "$line" in ''|'#'*) continue ;; esac
    DESELECT+=(--deselect "suites/mini_chat/${line%%::*}.py::${line#*::}")
done < "$HERE/excluded_tests.txt"

mkdir -p "$E2E/logs"
cd "$E2E"
E2E_BINARY="$ROOT/target/debug/cf-gears-example-server" \
    python -m pytest suites/mini_chat --mode offline -vv -p no:cacheprovider \
    "${DESELECT[@]}" --junitxml="$E2E/logs/benchmark-junit.xml" "$@"
