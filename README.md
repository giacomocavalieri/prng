# prng

[![Package Version](https://img.shields.io/hexpm/v/prng)](https://hex.pm/packages/prng)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/prng/)

🎲 A Pure Random Number Generator (PRNG) for Gleam

> ⚙️ This package works for both the Erlang and JavaScript target

## Installation

To add this package to your Gleam project:

```sh
gleam add prng
```

## Generating random values

This package can help you generate any kind of random values you can think of.
It can be useful in many different scenarios: when you need to simulate
non-deterministic actions, like rolling a dice or flipping a coin; when you need
to write [property based tests](https://ferd.ca/property-based-testing-basics.html);
or to make fun interactive games where you can spawn randomly generated enemies!

### A mindset shift

The way random values are generated may be a bit confusing at first, especially
coming from other languages like JavaScript. In such languages, random number
generation can be as simple as this:

```ts
const random_value: number = Math.random()
```

However, this should raise a lot of questions: what if I need those numbers to
be in a certain range?
How can I generate more complex values, like lists of
numbers?
Can I set the random seed to get deterministic and _reproducible results_ in a
test environment?

The `random` package tries to address all these questions by providing a nice
interface to define random value _generators_.
Let's have a look at an example to get a taste of what generating random values
will look like:

```gleam
let generator: Generator(Float) = random.float(0.0, 1.0)

// You truly want a random value and you don't need
// to reproduce your random runs
let random_value: Float = random.random_sample(generator)

// ... or you care about reproducing your random runs, 
// you can set the seed for reproduceability!
let seed1 = seed.new(42)
let seed2 = seed.new(42)

// Now value 1 and value 2 are the same, because
// they had the same seed. 
let value1 = random.sample(generator, with: seed1)
let value2 = random.sample(generator, with: seed2)
```

Notice a subtle but fundamental difference: you're no longer simply generating
a value, you're _describing_ the values you want to generate and you can
take those out of a generator with a variety of functions, like `sample`.

This neat trick can give two great features:

- _Composability:_ it's easy to describe simple generators and compose them
  together to generate complex data structures in an expressive way. The library
  has a rich API to create and compose generators, you can have a look at it
  [here](https://hexdocs.pm/prng/).
- _Reproducibility:_ you can decide the random seed used to generate the random
  values from a generator. The algorithm for the pseudo number generation will
  always yield the same results given the same starting seed!  
  The `random` package also goes out of its way to make sure that the random
  number generation _works exactly the same on all Gleam targets,_ so you won't
  get any discrepancies just by compiling to different targets

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
