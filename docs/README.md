# The library, module by module

One module today. Each is at the root of the repository and is included in full:

```c
#include <teko_std/strings.tk>
```

---

## `strings.tk`

`str` is a NUL-terminated string **by pointer** (teko's
[types.md](https://github.com/teko-org/teko-lang/blob/main/docs/reference/types.md)): there
is no separate string object, no length field, and no builder. So a function here either
reads through the pointer it was given — a **view**, no allocation at all — or asks the
runtime arena for a block of its own, and then `str_free` is what hands that block back.

| signature | answers | allocates |
|---|---|---|
| `i64 str_at(str s, i64 i)` | byte `i` of `s`, zero-extended; `0` at the terminator | no |
| `bool str_is_space(i64 c)` | is `c` one of the ASCII blanks ` `, `\t`, `\n`, `\r` | no |
| `bool str_equals(str a, str b)` | do the two hold the same bytes | no |
| `bool str_starts_with(str s, str prefix)` | does `s` begin with `prefix`; an empty prefix is always there | no |
| `bool str_ends_with(str s, str suffix)` | does `s` end with `suffix` | no |
| `i64 str_index_of(str s, str needle)` | index of the first `needle` in `s`, or `-1`; an empty needle is at `0` | no |
| `bool str_contains(str s, str needle)` | `str_index_of(s, needle) >= 0` | no |
| `str str_trim_start(str s)` | `s` without its leading blanks — a **view** into `s` | no |
| `str str_dup_range(str s, i64 from, i64 to)` | the bytes `[from, to)` as a new string; panics on an invalid range, like the runtime's array guards | **yes** |
| `str str_trim(str s)` | `s` without its leading and trailing blanks | **yes** |
| `str str_to_upper(str s)` | `s` with `a`-`z` raised; every other byte copied | **yes** |
| `str str_to_lower(str s)` | `s` with `A`-`Z` lowered; every other byte copied | **yes** |
| `void str_free(str s)` | gives a string this module allocated back to the arena | — |

### Why three of them cannot be views

`str_trim`, `str_to_upper` and `str_to_lower` produce bytes the original does not have:
a NUL where the trimmed string ends, an upper-cased byte where a lower-cased one was.
`str_trim_start` and `str_ends_with` need neither, so they read through
[`tk_str_slice`](https://github.com/teko-org/teko-lang/blob/main/docs/reference/runtime.md),
which is pointer arithmetic and copies nothing.

### The block, and giving it back

An allocating function takes a block from teko's arena — 4 MiB with a free list per
16-byte size class — so `str_free` returns it to that list and the next call reuses it: a
loop that trims a million lines does not grow. `str_free` is for a string this module
allocated and for nothing else; a literal and a view own no block.

```teko
str t = str_trim("  hi there \n");
// ... use it ...
str_free(t);
```

`rt_live()` is the count of blocks handed out and not yet given back, which is how
[`tests/strings_test.tk`](../tests/strings_test.tk) proves the library leaks nothing.

### ASCII, not Unicode

`str_to_upper`, `str_to_lower` and `str_is_space` are ASCII. A byte outside `a`-`z` /
`A`-`Z` is copied unchanged, so the bytes of a multi-byte code point pass through
untouched rather than being corrupted — case mapping over Unicode is a later module, with
a table of its own.
