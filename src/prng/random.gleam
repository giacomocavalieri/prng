import gleam/float
import gleam/int
import gleam/list
import gleam/map.{Map}
import gleam/order.{Eq, Gt, Lt, Order}
import gleam/pair
import prng/seed.{Seed}

// DEFINITION AND FIELD ACCESSOR ----------------------------------------------- 

/// A `Generator(a)` is a data structure that _describes_ how to produce random
/// values of type `a`.
/// 
/// Take for example the following generator for random integers:
/// 
/// ```gleam
/// let dice_roll: Generator(Int) = random.int(1, 6)
/// ```
/// 
/// It is just describing the values that can be generated - in this case the
/// numbers from 1 to 6 - but it is not actually producing any value.
///
/// ## Getting values out of a generator
/// 
/// To actually get a value out of a generator you can use the `step` function:
/// it takes a generator and a `Seed` as input and produces a new seed and a
/// random value of the type described by the generator:
/// 
/// ```gleam
/// import prng/random
/// import prng/seed
///
/// let #(roll_result, updated_seed) = dice_roll |> random.step(seed.new(11))
///
/// roll_result
/// // -> 3
/// ```
/// 
/// The generator is completely deterministic: this means that - given the same
/// seed - it will always produce the same results, no matter how many times you
/// call the `step` function.
/// 
/// `step` will produce an updated seed that you can use for subsequent calls to
/// get different pseudo-random results:
/// 
/// ```gleam
/// let initial_seed = seed.new(11)
/// let #(first_roll, new_seed) = dice_roll |> random.step(initial_seed)
/// let #(second_roll, _) = dice_roll |> random.step(new_seed)
/// 
/// #(first_roll, second_roll)
/// // -> #(3, 2)
/// ```
/// 
pub opaque type Generator(a) {
  Generator(step: fn(Seed) -> #(a, Seed))
}

/// Given a `Generator(a)` produces a pseudo-random value of type `a` using the
/// given seed.
/// 
/// It also returns the new seed that can be used to make subsequent calls to
/// `step` to get other pseudo-random values.
/// 
/// ## Examples
/// 
/// ```gleam
/// let initial_seed = seed.new(11)
/// let dice_roll = random.int(1, 6)
/// let #(first_roll, new_seed) = random.step(dice_roll, initial_seed)
/// let #(second_roll, _) = random.step(dice_roll, new_seed)
///
/// #(first_roll, second_roll)
/// // -> #(3, 2)
/// ```
/// 
pub fn step(generator: Generator(a), seed: Seed) -> #(a, Seed) {
  generator.step(seed)
}

// BASIC FFI BUILDERS ----------------------------------------------------------

/// Returns a generator that can produce integers in the given inclusive range.
/// 
/// ## Examples
/// 
/// ```gleam
/// let one_to_five = random.int(1, 5)
/// let one_or_two = random.int(1, 2)
/// let close_to_zero = random.int(-5, 5)
/// ```
/// 
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
fn random_int(seed: Seed, from: Int, to: Int) -> #(Int, Seed)

/// TODO
/// 
pub fn float(from: Float, to: Float) -> Generator(Float) {
  use seed <- Generator
  let #(low, high) = sort_ascending(from, to, float.compare)
  random_float(seed, low, high)
}

@external(erlang, "ffi", "random_float")
@external(javascript, "../ffi.mjs", "random_float")
fn random_float(seed: Seed, from: Float, to: Float) -> #(Float, Seed)

// PURE GLEAM BUILDERS ---------------------------------------------------------

/// Returns a generator that will always produce the given value every time, no
/// matter the seed used.
/// 
/// ## Examples
/// 
/// ```gleam
/// let always_eleven = random.constant(11)
/// let #(result, _) = random.step(always_eleven, seed.new(1))
/// 
/// result
/// // -> 11
/// ```
/// 
pub fn constant(value: a) -> Generator(a) {
  use seed <- Generator
  #(value, seed)
}

/// TODO
/// 
pub fn uniform(first: a, others: List(a)) -> Generator(a) {
  weighted(#(1.0, first), list.map(others, pair.new(1.0, _)))
}

/// TODO
/// 
pub fn try_uniform(options: List(a)) -> Result(Generator(a), Nil) {
  case options {
    [first, ..rest] -> Ok(uniform(first, rest))
    [] -> Error(Nil)
  }
}

/// TODO
/// 
pub fn weighted(first: #(Float, a), others: List(#(Float, a))) -> Generator(a) {
  let normalise = fn(pair) { float.absolute_value(pair.first(pair)) }
  let total = normalise(first) +. float.sum(list.map(others, normalise))
  map(float(0.0, total), get_by_weight(first, others, _))
}

/// TODO
/// 
pub fn try_weighted(options: List(#(Float, a))) -> Result(Generator(a), Nil) {
  case options {
    [first, ..rest] -> Ok(weighted(first, rest))
    [] -> Error(Nil)
  }
}

fn get_by_weight(
  first: #(Float, a),
  others: List(#(Float, a)),
  countdown: Float,
) -> a {
  let #(weight, value) = first
  case others {
    [] -> value
    [second, ..rest] -> {
      let positive_weight = float.absolute_value(weight)
      case float.compare(countdown, positive_weight) {
        Lt | Eq -> value
        Gt -> get_by_weight(second, rest, countdown -. positive_weight)
      }
    }
  }
}

/// Returns a generator that chooses between two values with equal probability.
/// 
/// This is a shorthand for `random.uniform(one, [other])`.
/// 
/// ## Examples
/// 
/// ```gleam
/// pub type CoinFlip {
///   Heads
///   Tails
/// }
/// 
/// let flip = random.choose(Heads, Tails)
/// let #(result, _) = random.step(flip, seed.new(11))
/// 
/// result
/// // -> TODO
/// ```
/// 
pub fn choose(one: a, or other: a) -> Generator(a) {
  uniform(one, [other])
}

// DATA STRUCTURES -------------------------------------------------------------

/// Returns a generator that can produce random pairs of values obtained from
/// the given generators.
/// 
/// ## Examples
/// 
/// ```gleam
/// let one_to_five = 
/// ```
/// 
pub fn pair(one: Generator(a), with other: Generator(b)) -> Generator(#(a, b)) {
  map2(one, other, with: pair.new)
}

/// Returns a generator for lists of the given size.
/// The list's elements are randomly generated using the provided generator.
/// 
/// ## Examples
/// 
/// ```gleam
/// let dice_roll = random.int(1, 6)
/// let ten_rolls = random.list(dice_roll, 10)
/// let #(rolls, _) = random.step(ten_rolls, seed.new(11))
/// 
/// rolls
/// // -> [4, 3, 2, 3, 6, 6, 5, 5, 2, 3]
/// ``` 
/// 
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

/// TODO.
/// 
pub fn dictionary(
  size: Int,
  keys: Generator(k),
  values: Generator(v),
) -> Generator(Map(k, v)) {
  pair(keys, values)
  |> list(of: size)
  |> map(map.from_list)
}

// MAPPING ---------------------------------------------------------------------

/// TODO.
/// 
pub fn then(
  generator: Generator(a),
  do generator_from: fn(a) -> Generator(b),
) -> Generator(b) {
  use seed <- Generator
  let #(value, seed) = generator.step(seed)
  generator_from(value).step(seed)
}

/// TODO
/// 
pub fn map(generator: Generator(a), with fun: fn(a) -> b) -> Generator(b) {
  use seed <- Generator
  let #(value, seed) = generator.step(seed)
  #(fun(value), seed)
}

/// TODO
/// 
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

/// TODO
/// 
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

/// TODO
/// 
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

/// TODO
/// 
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
