# Contributing

## The rules that are not negotiable

- **English only.** Documentation, code comments, commit messages, PR bodies, workflow
  comments. `sh scripts/check-language.sh` fails on Portuguese in a tracked source.
- **Every fixture carries `// expect-exit: N`** in its header. No oracle, no fixture: the
  exit code is the assertion, and CI compares it.
- **Every new function is exercised** by `tests/`, and a function that allocates is
  exercised with `rt_live()` back to the floor it started at — a library that leaks is a
  library that fails the fixture.
- **The library is written in teko**, not in the `mc` core dressed up as teko: `str`,
  `bool`, classes and `T[]` are the surface, and
  [teko's reference](https://github.com/teko-org/teko-lang/tree/main/docs/reference) is what
  says which of them a given tag accepts.
- **Nothing here patches `mc` or teko.** A defect on either side is reported to that
  project with a minimal reproducer; it is never worked around in this repository.

## The loop

```sh
git clone --branch "v$(sed -n 's/^version *= *"\(.*\)"/\1/p' mc.lock | head -1)" \
    https://github.com/teko-org/teko-lang.git deps/teko
mc build . --config teko.toml     # or the config your host derives (README.md)
./build/strings_test; echo $?     # 42
sh scripts/check-language.sh
```

A change lands through a pull request with CI green — the required check is
`teko_std build && run`, the aggregator over both native legs and the language check.

## Adding a module

1. The source goes at the **root**, `<name>.tk`: the library is flat, and
   `#include <teko_std/<name>.tk>` is how a consumer reaches it.
2. Add it to `[package].files` in `mc.toml`, in `LC_ALL=C` byte order, and to
   `[package].check` if it compiles as a unit of its own.
3. Add `tests/<name>_test.tk` with `// expect-exit: 42` and a numbered check per function.
4. Add its table to `docs/README.md`.

## Version

`vX.Y.Z`, and its minor moves **with `teko`**: `teko_std` 0.7.x is the library `teko` 0.7.y
compiles. Raising the dependency means raising the version row in `mc.lock`, its tree hash,
and `MC_VERSION` to the `mc` release that teko tag is built by.

## Releasing

A tag is not a release: pushing `vX.Y.Z` runs the gate, checks `[package].version` in
`mc.toml` against the tag, and only then creates the GitHub Release the registry looks for.
See README.md § Releasing for the full sequence and what the owner still has to do once on
the registry.
