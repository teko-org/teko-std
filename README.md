# teko_std

The standard library of [teko](https://github.com/teko-org/teko-lang), published as a
package for [`mc`](https://github.com/minicompiler/mc)'s registry: one flat library of
`.tk` sources a teko program includes by name.

```c
#include <teko_std/strings.tk>
```

The library is versioned in **lockstep** with the compiler: `teko_std` 0.4.0 is the library
`teko` 0.4.0 compiles.

Dual-licensed under [MIT](LICENSE-MIT) or [Apache-2.0](LICENSE-APACHE), at your option.
