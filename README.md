# almide/dfa

Multi-pattern DFA matching for [Almide](https://github.com/almide/almide).

Compiles a *set* of regular expressions into a single deterministic automaton and reports the **leftmost-longest** match in linear time. Built for lexers, scanners, and anything that runs many patterns over a lot of text.

Pure Almide. No `@extern`, so it runs wherever Almide runs — native or WebAssembly.

## Why not `almide/regex`

The standard library already ships a regex engine (`stdlib/regex_engine.almd`, 665 lines, zero `@extern`). It is a **greedy backtracking matcher with first-win alternation**. That is the right design for `find` / `replace` / `split` against a single pattern, and the wrong one for tokenizing.

| Requirement | `stdlib/regex` | `almide/dfa` |
|---|---|---|
| Longest match wins | ✗ first alternative wins | ✓ leftmost-longest |
| N patterns at one position | one at a time | ✓ one fused automaton |
| Cost per input byte | backtracking | ✓ one state transition |
| Worst case | can blow up | ✓ linear |

With first-win alternation, a lexer that knows both `=` and `==` can never produce `==`, and one that knows `in` and `instanceof` can never produce `instanceof`. That single fact is why this package exists.

The two are complementary rather than competing. Use `almide/regex` to manipulate text; use `almide/dfa` when the pattern set is fixed and the input is large.

## API

```almide
import dfa

// Compile a pattern set. Index in the list becomes the token id;
// a length tie goes to the lower id, so list keywords first.
fn compile(patterns: List[String]) -> Result[Dfa, String]

// Longest pattern matching at `at`, or none. Matches AT the position —
// it never searches forward; that is the caller's loop.
fn scan(dfa: Dfa, input: String, at: Int) -> Match?

// Match { id: Int, len: Int }
```

`scan` is the shape a lexer needs: at this position, which pattern matched, and how far.

```almide
let d = dfa.compile(["let", "[a-z]+", "[0-9]+", " +", "="])!
dfa.scan(d, "letter", 0)     // some(Match { id: 1, len: 6 }) — longest wins
dfa.scan(d, "let x", 0)      // some(Match { id: 0, len: 3 }) — tie → lower id
```

For the lexer loop, convert the input once and scan per position:

```almide
let cps = dfa.codepoints(input)
dfa.scan_cps(d, cps, at)
```

## Pipeline

```
pattern set
  → parse         (syntax.almd — shared dialect with stdlib/regex)
  → NFA           (nfa.almd — Thompson construction, all patterns fused)
  → DFA           (subset.almd — subset construction over codepoint classes)
  → minimize      (minimize.almd — Moore partition refinement)
  → table         (table.almd — dense state × class matrix, scanned at match time)
```

The alphabet of the table is not codepoints but equivalence classes: the
codepoint space is cut at every range boundary any pattern mentions, so a
handful of classes stands in for all 1,114,112 codepoints. Minimization is
Moore refinement rather than Hopcroft — the same minimal automaton, and
lexer tables are far too small for the asymptotic difference to matter.

## Non-goals

| Not supported | Why |
|---|---|
| Backreferences | Not a regular language. Cannot be compiled to a DFA |
| Lookahead / lookbehind | Same |
| Capture groups | A lexer needs a token id and a length, nothing more |
| Replacement, splitting | That is `almide/regex`'s job |

## Status

Implemented and tested, native and WASM. `tools/wasm-check.sh` builds the
public API for the wasm target and fails loudly if anything walls — run it
after touching any module; `almide test` alone can quietly fall back to
native.

## Used by

- [almide/parsegen](https://github.com/almide/parsegen) — the lexer half of a tree-sitter compatible parser generator
