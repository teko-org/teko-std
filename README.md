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

The library is versioned in **lockstep** with the compiler: `teko_std` 0.4.0 is the library
`teko` 0.4.0 compiles, and the two are released together.

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
teko     = "0.4.0"
teko_std = "0.4.0"

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
compiler tag it is locked to: `teko` v0.4.0 carries `MC_VERSION` 0.15.13 and is built by
that release, so this repository names the same one. It rises when the `teko` tag in
[`mc.lock`](mc.lock) rises.

The `teko` package is **not published yet**, so its tree is vendored — the offline road
`mc` already has, with the lock rehashed on every build:

```sh
git clone --branch "v$(sed -n 's/^version *= *"\(.*\)"/\1/p' mc.lock | head -1)" \
    https://github.com/teko-org/teko-lang.git deps/teko
```

`[replace] teko = "../teko-lang"` is **not** the road here, and cannot be until the package
exists: `mc` resolves a dependency's tree before it reads `[replace]`, so a name that is
neither vendored nor installed stops at `mc: teko 0.4.0 is not fetched` however the
replacement is spelled. `deps/teko` is what a build reads, and `mc.lock` is what pins it.

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

`[package].toolchain = "teko"` is what the registry classifies on, and `[package].modules`
is the taught compiler it has to build **before** it can compile the `check` unit, which is
written in teko. Neither key is live yet — `mc` ignores an unknown `[package]` key — so
today the validator would hand `strings.tk` to the stock `mc`. The whole agreement is
teko's own [`docs/specs/packages.md`](https://github.com/teko-org/teko-lang/blob/main/docs/specs/packages.md).

## Contributing

[CONTRIBUTING.md](CONTRIBUTING.md). This repository is **English-only**, and
`scripts/check-language.sh` proves it on every run.

Dual-licensed under [MIT](LICENSE-MIT) or [Apache-2.0](LICENSE-APACHE), at your option.
