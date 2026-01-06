# prng

[![Package Version](https://img.shields.io/hexpm/v/prng)](https://hex.pm/packages/prng)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/prng/)

🎲 A Pure Random Number Generator (PRNG) for Gleam

This package can help you generate any kind of random values you can think of.
It can be useful in many different scenarios: when you need to simulate
non-deterministic actions, like rolling a dice or flipping a coin; when you need
to write [property based tests](https://ferd.ca/property-based-testing-basics.html);
or to make fun interactive games where you can spawn randomly generated enemies!

To add this package to your Gleam project:

```sh
gleam add prng
```

And you can start generating random values:

```gleam
import prng/random
import prng/seed

pub fn main() {
  // A generator describes which kind of random values to produce:
  let generator = random.int(0, 10)

  // One can take values out of a generator using the `step` function.
  // Using the same initial seed will always produce the same value!
  let #(value, _) = random.step(generator, seed.new(11))
  let #(other_value, _) = random.step(generator, seed.new(11))
  assert value == 10
  assert other_value == 10
}
```

The `step` function also produces a new seed you can use on successive calls to
generate a new pseudo-random value each time you call it:

```gleam
pub fn main() {
  let generator = random.int(0, 10)
  let #(value, next_seed) = random.step(generator, seed.new(11))
  let #(other_value, _) = random.step(generator, next_seed)
  assert value == 10
  assert other_value == 4
}
```

## References

This package and its documentation are based on the awesome
[Elm implementation](https://package.elm-lang.org/packages/elm/random/1.0.0/)
of [Permuted Congruential Generators](https://www.pcg-random.org).
They have great documentation full of clear and useful examples; if you are
curious, give it a look and show Elm some love!

## Contributing

If you think there's any way to improve this package, or if you spot a bug don't
be afraid to open PRs, issues or requests of any kind! Any contribution is
welcome 💜
