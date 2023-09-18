import gleam/bitwise
import gleam/int
import gleam/order.{Eq, Gt, Lt, Order}
import gleam/pair
import gleam/result
import prng/internals/int_32
import prng/seed.{Seed}

pub opaque type Generator(a) {
  Generator(step: fn(Seed) -> #(a, Seed))
}

pub fn step(generator: Generator(a), seed: Seed) -> #(a, Seed) {
  generator.step(seed)
}

// --- BASIC BUILDERS ---

pub fn int(from: Int, to: Int) -> Generator(Int) {
  use seed <- Generator
  let #(low, high) = sort_ascending(from, to, int.compare)
  let range = high - low + 1
  case is_power_of_two(range) {
    True -> fast_path(range, seed)
    False -> slow_path(range, seed, low)
  }
}

fn fast_path(range: Int, seed: Seed) -> #(Int, Seed) {
  let value = int_32.truncate(bitwise.and(range - 1, seed.to_int(seed)))
  #(value, seed.next(seed))
}

fn slow_path(range: Int, seed: Seed, low: Int) -> #(Int, Seed) {
  let threshold =
    int.remainder(int_32.truncate(-range), by: range)
    |> result.unwrap(0)
    |> int_32.truncate()

  account_for_bias(seed, range, threshold, low)
}

fn account_for_bias(
  seed: Seed,
  range: Int,
  threshold: Int,
  low: Int,
) -> #(Int, Seed) {
  let value = seed.to_int(seed)
  let seed = seed.next(seed)
  case value < threshold {
    True -> account_for_bias(seed, range, threshold, low)
    False -> #(result.unwrap(int.remainder(value, by: range), 0) + low, seed)
  }
}

// --- FIND A NAME FOR THIS ---

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

pub fn pair(one: Generator(a), with other: Generator(b)) -> Generator(#(a, b)) {
  map2(one, other, with: pair.new)
}

pub fn constant(value: a) -> Generator(a) {
  use seed <- Generator
  #(value, seed)
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

// --- GENERIC UTILITY FUNCTIONS ---

fn is_power_of_two(number: Int) -> Bool {
  bitwise.and(number - 1, number) == 0
}

fn sort_ascending(one: a, other: a, with compare: fn(a, a) -> Order) -> #(a, a) {
  case compare(one, other) {
    Lt | Eq -> #(one, other)
    Gt -> #(other, one)
  }
}
