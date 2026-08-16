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

## Planned API

```almide
// Compile a pattern set. Index in the list becomes the token id.
fn compile(patterns: List[String]) -> Dfa

// Longest pattern matching at `at`, or None.
fn scan(dfa: Dfa, input: String, at: Int) -> Match?

// Match { id: Int, len: Int }
```

`scan` is the shape a lexer needs: at this position, which pattern matched, and how far.

## Pipeline

```
pattern set
  → parse         (shared dialect with stdlib/regex)
  → NFA           (Thompson construction)
  → DFA           (subset construction, all patterns fused)
  → minimize      (Hopcroft)
  → transition table
```

## Non-goals

| Not supported | Why |
|---|---|
| Backreferences | Not a regular language. Cannot be compiled to a DFA |
| Lookahead / lookbehind | Same |
| Capture groups | A lexer needs a token id and a length, nothing more |
| Replacement, splitting | That is `almide/regex`'s job |

## Status

Design phase. Nothing is implemented yet.

## Used by

- [almide/parsegen](https://github.com/almide/parsegen) — the lexer half of a tree-sitter compatible parser generator
