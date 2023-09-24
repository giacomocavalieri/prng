import gleam/int
import gleam/order.{Eq, Gt, Lt, Order}
import gleam/pair
import prng/seed.{Seed}

// DEFINITION AND FIELD ACCESSOR ----------------------------------------------- 

pub opaque type Generator(a) {
  Generator(step: fn(Seed) -> #(a, Seed))
}

pub fn step(generator: Generator(a), seed: Seed) -> #(a, Seed) {
  generator.step(seed)
}

// BASIC FFI BUILDERS ----------------------------------------------------------

pub fn int(from: Int, to: Int) -> Generator(Int) {
  use seed <- Generator
  let #(low, high) = sort_ascending(from, to, int.compare)
  random_int(seed, low, high)
}

fn sort_ascending(one: a, other: a, with compare: fn(a, a) -> Order) -> #(a, a) {
  case compare(one, other) {
    Lt | Eq -> #(one, other)
    Gt -> #(other, one)
  }
}

@external(erlang, "ffi", "random_int")
@external(javascript, "../ffi.mjs", "random_int")
fn random_int(seed: Seed, low: Int, high: Int) -> #(Int, Seed)

// PURE GLEAM BUILDERS ---------------------------------------------------------

pub fn constant(value: a) -> Generator(a) {
  use seed <- Generator
  #(value, seed)
}

// GENERATOR COMBINATORS -------------------------------------------------------

pub fn lazy(generator: fn() -> Generator(a)) -> Generator(a) {
  use seed <- Generator
  generator().step(seed)
}

pub fn then(
  generator: Generator(a),
  do generator_from: fn(a) -> Generator(b),
) -> Generator(b) {
  use seed <- Generator
  let #(value, seed) = generator.step(seed)
  generator_from(value).step(seed)
}

pub fn map(generator: Generator(a), with fun: fn(a) -> b) -> Generator(b) {
  use seed <- Generator
  let #(value, seed) = generator.step(seed)
  #(fun(value), seed)
}

pub fn map2(
  one: Generator(a),
  other: Generator(b),
  with fun: fn(a, b) -> c,
) -> Generator(c) {
  use seed <- Generator
  let #(a, seed) = one.step(seed)
  let #(b, seed) = other.step(seed)
  #(fun(a, b), seed)
}

pub fn map3(
  one: Generator(a),
  two: Generator(b),
  three: Generator(c),
  with fun: fn(a, b, c) -> d,
) -> Generator(d) {
  use seed <- Generator
  let #(a, seed) = one.step(seed)
  let #(b, seed) = two.step(seed)
  let #(c, seed) = three.step(seed)
  #(fun(a, b, c), seed)
}

pub fn map4(
  one: Generator(a),
  two: Generator(b),
  three: Generator(c),
  four: Generator(d),
  with fun: fn(a, b, c, d) -> e,
) -> Generator(e) {
  use seed <- Generator
  let #(a, seed) = one.step(seed)
  let #(b, seed) = two.step(seed)
  let #(c, seed) = three.step(seed)
  let #(d, seed) = four.step(seed)
  #(fun(a, b, c, d), seed)
}

pub fn map5(
  one: Generator(a),
  two: Generator(b),
  three: Generator(c),
  four: Generator(d),
  five: Generator(e),
  with fun: fn(a, b, c, d, e) -> f,
) -> Generator(f) {
  use seed <- Generator
  let #(a, seed) = one.step(seed)
  let #(b, seed) = two.step(seed)
  let #(c, seed) = three.step(seed)
  let #(d, seed) = four.step(seed)
  let #(e, seed) = five.step(seed)
  #(fun(a, b, c, d, e), seed)
}

pub fn pair(one: Generator(a), with other: Generator(b)) -> Generator(#(a, b)) {
  map2(one, other, with: pair.new)
}

pub fn list(from generator: Generator(a), of length: Int) -> Generator(List(a)) {
  use seed <- Generator
  do_list([], seed, generator, length)
}

fn do_list(
  acc: List(a),
  seed: Seed,
  generator: Generator(a),
  length: Int,
) -> #(List(a), Seed) {
  case length <= 0 {
    True -> #(acc, seed)
    False -> {
      let #(value, seed) = generator.step(seed)
      do_list([value, ..acc], seed, generator, length - 1)
    }
  }
}
