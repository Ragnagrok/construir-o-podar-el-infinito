# Building or Pruning the Infinite

Proof of concept for the article *Building or Pruning the Infinite*
([English](https://blog.ragnagrok.com/en/2026-10-24-construir-o-podar-el-infinito) ·
[español](https://blog.ragnagrok.com/es/2026-10-24-construir-o-podar-el-infinito)):
the article's line, made to run.

```haskell
program = head . filter meetsSpec $ samples llm prompt
```

The idea in one line: a model is a lazy generator of programs, and what decides which one you
keep is the filter. Here the "model" is a cheap stand-in (no API calls): something that produces
an endless stream of candidate programs for "is `x` even?". The same stream goes through two
filters: the vibecoding one (it typechecks and looks right on the three inputs I tried) and the
spec (it typechecks, passes those examples, and satisfies the properties that define evenness).

## What it prints

`cabal run demo`, verbatim (it's deterministic; `check.sh` diffs it against
`expected-output.txt`):

```
The vibecoding filter: it looks right on what I tried
  tried 0..2:  not (x == 1)                      wrong at x = 3
  tried 0..3:  0 == x `mod` 2                    correct up to 100000
  ...

The spec as a filter: head . filter meetsSpec $ samples llm prompt
  0 == x `mod` 2                    correct up to 100000

A different model (random, seed 7), both filters
  tried 0..2:  not (not (not (x == 1)))          wrong at x = 3
  spec:        0 == x `mod` 2                    correct up to 100000

The ratchet: each check only removes candidates
  869285 candidates up to size 7
  33250 typecheck
  194 also pass 0, 1, 2; 78 of them are wrong
  116 also satisfy the properties; 0 of them are wrong
```

After three tries, the first program that "looks right" is `not (x == 1)`: it says 0 and 2 are
even and 1 isn't, and it's wrong at 3. That's the article's *overfitting to the observer*. With
the properties as the filter, the first program accepted is ``0 == x `mod` 2``, from either model.
And among all the programs up to size 7, 78 of the 194 that pass the three tries are wrong; none
of the ones that also satisfy the properties are.

## What's here

| File | What it is |
|---|---|
| `src/Naturals.hs` | The article's `N`, `two`, `nats`, `two'`, `isEven`, `evens`, `evens'`, and `infinity = S infinity`. |
| `src/Expr.hs` | A tiny language of candidate programs over one `Int` variable, with a type checker, an evaluator and an enumerator by size. |
| `src/Search.hs` | Two stand-in models (an enumerator and a seeded random sampler), the two filters, and `program`. |
| `examples/Main.hs` | The demo. `expected-output.txt` is what it prints. |
| `test/CheckSearch.hs` | The same claims, checked with QuickCheck's own random generation. |
| `check.sh` | Builds, diffs the demo's output, runs the tests. |

The article's identifiers are in Spanish; here they're in English: `dos` → `two`, `esPar` →
`isEven`, `pares` → `evens`, `muestras` → `samples`, `meGusta` → `looksRight`, `cumpleSpec` →
`meetsSpec`, `tipa` → `typechecks`, `pasaTests` → `passesTests`, `cumplePropiedades` →
`satisfiesProperties`, `programa` → `program`.

The spec, as properties, is just the definition of `isEven` from the article turned into
equations, with no reference answer:

```haskell
f 0 == True
f 1 == False
f (n + 2) == f n          -- for every natural n
```

## Running it

With GHC 9.12 and cabal:

```sh
./check.sh       # builds, checks the demo's output, runs the QuickCheck tests
cabal run demo
```

## What this proof of concept doesn't cover

- **The model isn't an LLM.** `Model` is `Prompt -> [Expr]`, and both stand-ins ignore the prompt.
  A real LLM would condition on it and produce text that would need parsing first; that's where
  "it typechecks" would start doing real work.
- **The space is tiny on purpose.** One variable, nine constructors, four literals. A bigger
  grammar has many more programs that look right on three tries.
- **The properties are checked on a sample.** The filter has to be a pure function, so it draws
  its inputs from a fixed seed, growing in size like QuickCheck does. An early version drew only
  large random numbers, and `not (x == 1)` passed the "spec": the step property only fails at
  n = 1. A property tested on a sample is still a sample; QuickCheck's habit of starting small
  is what puts the boundary in it.
- **`x mod 0` is taken to be 0**, so every candidate is a total function.

## Further reading

- Hughes (1989), [*Why Functional Programming Matters*](https://www.cse.chalmers.se/~rjmh/Papers/whyfp.pdf): generate and select, glued by laziness.
- Wadler (1985), [*How to Replace Failure by a List of Successes*](https://doi.org/10.1007/3-540-15975-4_33).
- Claessen and Hughes (2000), [*QuickCheck: A Lightweight Tool for Random Testing of Haskell Programs*](https://dl.acm.org/doi/10.1145/351240.351266).
- Jacobs and Rutten (1997), [*A Tutorial on (Co)Algebras and (Co)Induction*](https://www.cs.ru.nl/B.Jacobs/PAPERS/JR.pdf).
