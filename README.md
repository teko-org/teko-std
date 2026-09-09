# teko_std

The standard library of [teko](https://github.com/teko-org/teko-lang), published as a
package for [`mc`](https://github.com/minicompiler/mc)'s registry: one flat library of
`.tk` sources a teko program includes by name.

```c
#include <teko_std/strings.tk>
```

One **flat** library, and every entry is named in full — the extension is spelled out,
because `mc` drops a trailing `.mc` from an angle-bracket name and does not drop `.tk`.
There is no `lib` key in the manifest, so a bare `<teko_std>` has no answer and is refused.

The library is versioned in **lockstep** with the compiler at the minor: `teko_std` 0.9.x is
the library `teko` 0.9.y compiles, the minor moves together, and a patch of either moves on
its own (a manifest fix of the library alone moves only its patch).

## What is in it

| module | what it holds |
|---|---|
| [`strings.tk`](strings.tk) | what a program needs over `str` and [the runtime](https://github.com/teko-org/teko-lang/blob/main/docs/reference/runtime.md) does not already give it |

Every function, with its signature and what it answers, is [docs/README.md](docs/README.md).

## Consuming it

Once both packages are published, a consumer pins the two, names the taught compiler in its
own build config and includes the library by package name:

```toml
[deps]
teko     = "0.9.0"
teko_std = "0.9.0"

[compiler]
core    = "<mc/core_min>"
modules = ["<teko/core_teko.mc>", "<teko/teko.tk>", "user.mc"]
out     = "build/teko"
```

```c
// user.mc, the project's own module: a package never defines `user_init`
void user_init() {
    teko_init();
}
```

`modules` names **three** files, in that order: `core_teko.mc` is the taught compiler's own
`main()` and the four `mc` parts it registers (`<mc/core_min>` alone has no machine, no
writer, no `mc build` and no `#include <name>`), `teko.tk` is the language, and `user.mc` is
the project's own.

## Working on the library

`mc` is pinned by [`MC_VERSION`](MC_VERSION), and the pin of a library is the pin of the
compiler tag it is locked to: `teko` v0.9.0 carries `MC_VERSION` 0.15.23 and is built by
that release, so this repository names the same one. It rises when the `teko` tag in
[`mc.lock`](mc.lock) rises.

`teko` is published on the mc registry, so the dependency comes the normal road:

```sh
mc pkg sync --yes
```

fetches `teko` at the version `[deps]` names into `~/.mc/libs/teko/`, checks it against the
tree hash the registry published, and writes `mc.lock`. The offline road is a vendored
checkout of the same tag, which `mc build` rehashes against the lock on every build:

```sh
git clone --branch "v$(sed -n 's/^version *= *"\(.*\)"/\1/p' mc.lock | head -1)" \
    https://github.com/teko-org/teko-lang.git deps/teko
```

CI takes the vendored road (`.github/workflows/std.yml`), so a runner never depends on the
registry being up; either way the tree a build reads is the one `mc.lock` pins, byte for byte.

Then, from the repository root:

```sh
mc build . --config teko.toml           # the taught compiler, then tests/strings_test.tk
./build/strings_test; echo $?           # 42
sh scripts/check-language.sh
```

`teko.toml` names CI's own `linux`/`x86_64`; another host derives its own config instead of
editing that file, and runs the whole fixture directory the way CI does:

```sh
sed -e 's/^os   = .*/os   = "macos"/' -e 's/^arch = .*/arch = "aarch64"/' \
    teko.toml >mc.macos.toml
mc build . --config mc.macos.toml
for src in tests/*.tk; do
    n=$(basename "$src" .tk)
    want=$(sed -n 's#^// expect-exit: *##p' "$src" | head -1)
    sed -e "s#^entry = .*#entry = \"tests/$n.tk\"#" -e "s#^out   = .*#out   = \"build/$n\"#" \
        mc.macos.toml >"mc.$n.toml"
    ./build/teko build . --config "mc.$n.toml" --entry-only && "./build/$n"
    echo "$n exit=$?  want=$want"; rm -f "mc.$n.toml"
done
```

Every fixture carries `// expect-exit: N` in its header, and that number is the assertion.

## The two files at the root

| file | role |
|---|---|
| [`mc.toml`](mc.toml) | the package manifest: `[package]` only, read by `mc pkg` and by the registry |
| [`teko.toml`](teko.toml) | the build config — `mc build . --config teko.toml` |

They cannot be one file: `mc pkg hash DIR` reads `DIR/mc.toml` and takes no `--config`.
`teko.toml` is deliberately not listed in `[package].files`: it says how this repository
builds itself, not what a consumer receives.

`[package].language = "teko"` is what the registry classifies on (it falls back to
`[deps].teko` when `language` is absent, but this library names it outright), and
`[package].modules` is the taught compiler it has to build **before** it can compile the
`check` unit, which is written in teko. `[package].version` is what a release's tag is
checked against (`.github/workflows/release.yml`). `mc` itself reads none of the three — it
ignores unknown `[package]` keys — so a local `mc build` is unaffected by them; `mc pkg
hash` still moves when they change, since it digests the bytes of `mc.toml`. The whole
agreement is teko's own
[`docs/specs/packages.md`](https://github.com/teko-org/teko-lang/blob/main/docs/specs/packages.md).

## Releasing

A `v*` tag is what `.github/workflows/release.yml` turns into a package: pushing one runs
`teko_std CI` (`std.yml`) over the tag, checks that `[package].version` in `mc.toml` matches
the tag, builds the taught compiler out of the tag's own `mc.lock` pin and compiles the
`[package].check` unit with it, then creates the tag's **GitHub Release** — the registry
publishes only a tag that has one, never a bare tag (mc's own
[docs/guide/27-publishing.md](https://github.com/minicompiler/mc/blob/main/docs/guide/27-publishing.md)
§ 4). Announcing that release to the registry needs, once and by the owner:

1. the repository registered at <https://minicompiler.dev/me> (§ 3 of the same guide);
2. its dependency, `teko` (`[deps] teko = "0.9.0"`, the pinned version above), registered and
   published first — the registry resolves `teko_std`'s own `[deps]` the same way `mc pkg`
   does, so a consumer's build fails until `teko` itself is a published package;
3. the repository variable `TEKO_REGISTRY_PUBLISH` set to `1` — without it the release still
   happens, but the announcement step only prints what it would have sent;
4. optionally, an account token from `/me` > Tokens (scope `poll` only), stored as the
   repository secret `MC_REGISTRY_TOKEN`, so a re-run polls as the owner rather than
   anonymously (guide § 7).

## Contributing

[CONTRIBUTING.md](CONTRIBUTING.md). This repository is **English-only**, and
`scripts/check-language.sh` proves it on every run.

Dual-licensed under [MIT](LICENSE-MIT) or [Apache-2.0](LICENSE-APACHE), at your option.
