#!/usr/bin/env bash
# The WASM target is the point of this package, and `almide test` does not
# prove it — a test can quietly fall back to native. Only `almide build
# --target wasm` reports a lowering wall. This builds a throwaway entry point
# that touches the public API and fails loudly if anything walls.
set -euo pipefail
cd "$(dirname "$0")/.."
trap 'rm -f src/__wasm_check.almd' EXIT
cat > src/__wasm_check.almd <<'EOF'
import self.syntax

effect fn main() -> Unit = {
  let r = syntax.parse("[a-z_][a-z0-9_]*|\\d+")
  println(match r { ok(_) => "parsed", err(e) => e })
}
EOF
almide build src/__wasm_check.almd --target wasm -o /tmp/dfa-wasm-check.wasm
