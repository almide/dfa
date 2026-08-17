#!/usr/bin/env bash
# The WASM target is the point of this package, and `almide test` does not
# prove it — a test can quietly fall back to native. Only `almide build
# --target wasm` reports a lowering wall. This builds a throwaway entry point
# that touches the public API and fails loudly if anything walls.
set -euo pipefail
cd "$(dirname "$0")/.."
trap 'rm -f src/__wasm_check.almd' EXIT
cat > src/__wasm_check.almd <<'EOF'
import self as dfa

effect fn main() -> Unit = {
  let d = dfa.compile(["[a-z_][a-z0-9_]*", "\\d+", "[ \t]+"])!
  match dfa.scan(d, "ident42 7", 0) {
    some(m) => println("id=${int.to_string(m.id)} len=${int.to_string(m.len)}"),
    none => println("no match"),
  }
}
EOF
almide build src/__wasm_check.almd --target wasm -o /tmp/dfa-wasm-check.wasm
