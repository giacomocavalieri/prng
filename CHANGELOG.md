# Changelog

> - 💥 is for breaking changes
> - 💡 is for non breaking changes
> - 📓 is for documentation-related changes
> - 🐛 is for bug fixes

## v4.0.1 - 2025-01-01 (Happy new year! 🎉)

- 🐛 Fix a bug that would cause an infinite loop when generating integers for
  the javascript target.

## v4.0.0 - 2024-12-02

- 💥 Remove deprecated `Iterator` in favor of `Yielder` from `gleam_yielder`,
  and rename functions accordingly.
- 💥 `to_random_iterator` becomes `to_random_yielder`.
- 💥 `to_iterator` becomes `to_yielder`.

## v3.0.3 - 2024-04-22

- 💡 Rename ffi modules to avoid conflicts on the Erlang target.

## v3.0.2 - 2024-03-19

- 🐛 Fixed a bug in the `fixed_size_dict` function.

## v3.0.1 - 2024-01-19

- 💡 Drop use of reserved keywords.
- 💡 Replace deprecated `gleam/map` with `gleam/dict`.

## v3.0.0 - 2023-11-08

- 💡 The `prng/random` module gains the `set` function.
- 💡 The `prng/random` module gains the `fixed_size_set` function.
- 💡 The `prng/random` module gains the `dict` function.
- 💡 The `prng/random` module gains the `fixed_size_dict` function.
- 💡 The `prng/random` module gains the `bit_array` function.
- 💡 The `prng/random` module gains the `fixed_size_string` function.
- 💡 The `prng/random` module gains the `string` function.
- 💡 The `prng/random` module gains the `list` function.
- 💥 The `list` function in the `prng/random` module has been renamed to
  `fixed_size_list`.

## v2.0.0 - 2023-10-25

- 📓 The `prng/random` documentation has received some slight improvements.
- 💡 The `prng/seed` module gains the `random` function.
- 💥 The `sample` function in the `prng/random` module has been renamed to
  `random_sample`.
- 💡 The `prng/random` module gains a `sample` function that requires a seed as
  its second argument.

## v1.0.0 - 2023-09-29

- First release! 🎉
