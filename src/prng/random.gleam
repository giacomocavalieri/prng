//// This package provides many building blocks that can be used to define
//// pure generators of pseudo-random values.
//// 
//// This is based on the great
//// [Elm implementation](https://package.elm-lang.org/packages/elm/random/1.0.0/)
//// of [Permuted Congruential Generators](https://www.pcg-random.org).
//// 
//// _It is not cryptographically secure!_
//// 
//// You can use this cheatsheet to navigate the module documentation:
//// 
//// <table>
//// <tr>
////   <td>Building generators</td>
////   <td>
////     <a href="#int">int</a>,
////     <a href="#float">float</a>,
////     <a href="#uniform">uniform</a>,
////     <a href="#weighted">weighted</a>,
////     <a href="#choose">choose</a>,
////     <a href="#constant">constant</a>
////   </td>
//// </tr>
//// <tr>
////   <td>Transform and compose generators</td>
////   <td>
////     <a href="#map">map</a>,
////     <a href="#then">then</a>,
////     <a href="#list">list</a>,
////     <a href="#pair">pair</a>
////   </td>
//// </tr>
//// <tr>
////   <td>Getting reproducible values out of generators</td>
////   <td>
////     <a href="#step">step</a>,
////     <a href="#sample">sample</a>,
////     <a href="#to_iterator">to_iterator</a>
////   </td>
//// </tr>
//// <tr>
////   <td>Getting truly random values out of generators</td>
////   <td>
////     <a href="#random_sample">random_sample</a>,
////     <a href="#to_random_iterator">to_random_iterator</a>
////   </td>
//// </tr>
//// </table>  
//// 

import gleam/float
import gleam/int
import gleam/iterator.{Iterator}
import gleam/list
import gleam/order.{Eq, Gt, Lt, Order}
import gleam/pair
import prng/seed.{Seed}

// DEFINITION ------------------------------------------------------------------ 

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
/// ## Getting values out of a generator
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

// GETTING VALUES OUT OF GENERATORS --------------------------------------------

/// Steps a `Generator(a)` producing a random value of type `a` using the given
/// seed as the source of randomness.
/// 
/// The stepping logic is completely deterministic. This means that, given a
/// seed and a generator, you'll always get the same result.
/// 
/// This is why this function also returns a new seed that can be used to make
/// subsequent calls to `step` to get other random values.
/// 
/// Stepping a generator by hand can be quite cumbersome, so I recommend you
/// try [`to_iterator`](#to_iterator),
/// [`to_random_iterator`](#to_random_iterator), or [`sample`](#sample) instead.
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

/// Generates a single value using the given generator.
/// 
/// The initial seed is chosen randomly so you won't have control over which
/// value is generated and may get different results each time you call this
/// function.
/// 
/// This is useful if you want to quickly get a value out of a generator and
/// do not care about reproducibility (if you want to decide which seed is
/// used for the generation process you'll have to use `random.step`).
/// 
/// ## Examples
/// 
/// Imagine you want to perform some action, say only 40% of the times.
/// Your code may look like this:
/// 
/// ```gleam
/// let probability = random.float(0.0, 1.0)
/// case random.sample(probability) <= 0.4 {
///   True -> perform_action()
///   False -> Nil // do nothing
/// }
/// ```
/// 
pub fn sample(generator: Generator(a)) -> a {
  // ⚠️ [ref:iterator_infinite] this is based on the assumption that, a sampled
  // generator will always yield at least one value. This is true since the
  // `to_iterator` implementation produces an infinite stream of values.
  // However, if the implementation were to change this piece of code may break!
  let assert Ok(result) = iterator.first(to_random_iterator(generator))
  result
}

/// Turns the given generator into an infinite stream of random values generated
/// with it.
/// 
/// The initial seed is chosen randomly so you won't have control over which
/// values are generated and may get different results each time you call this
/// function.
/// 
/// If you want to have control over the initial seed used to get the infinite
/// sequence of values, you can use `to_iterator`.
/// 
pub fn to_random_iterator(from generator: Generator(a)) -> Iterator(a) {
  to_iterator(generator, seed.random())
}

/// Turns the given generator into an infinite stream of random values generated
/// with it.
/// 
/// `seed` is the seed used to get the initial random value and start the
/// infinite sequence.
/// 
/// If you don't care about the initial seed and reproducibility is not your
/// goal, you can use `to_random_iterator` which works like this function and
/// randomly picks the initial seed.
/// 
pub fn to_iterator(generator: Generator(a), seed: Seed) -> Iterator(a) {
  use seed <- iterator.unfold(from: seed)
  let #(value, new_seed) = step(generator, seed)
  // [tag:iterator_infinite] this will generate an infinite stream of values
  // since it never returns an `iterator.Done`
  iterator.Next(element: value, accumulator: new_seed)
}

// BASIC FFI BUILDERS ----------------------------------------------------------

/// The underlying algorith will work best for integers in the inclusive range 
/// going from `min_int` up to `max_int`.
/// 
/// It can generate values outside of that range, but they are "not as random".
/// 
pub const min_int = -2_147_483_648

/// The underlying algorith will work best for integers in the inclusive range 
/// going from `min_int` up to `max_int`.
/// 
/// It can generate values outside of that range, but they are "not as random".
/// 
pub const max_int = 2_147_483_647

/// Generates integers in the given inclusive range.
/// 
/// ## Examples
/// 
/// Say you want to model the outcome of a dice, you could use `int` like this:
/// 
/// ```gleam
/// let dice_roll = random.int(1, 6)
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

/// Generates floating point numbers in the given inclusive range.
/// 
/// ## Examples
/// 
/// ```gleam
/// let probability = random.float(0.0, 1.0)
/// ``` 
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

/// Always generates the given value, no matter the seed used.
/// 
/// ## Examples
/// 
/// ```gleam
/// let always_eleven = random.constant(11)
/// random.sample(always_eleven)
/// // -> 11
/// ```
/// 
pub fn constant(value: a) -> Generator(a) {
  use seed <- Generator
  #(value, seed)
}

/// Generates values from the given ones with an equal probability.
/// 
/// This generator can guarantee to produce values since it always takes at
/// least one item (as its first argument); if it were to accept just a list of
/// options, it could be called like this:
/// 
/// ```gleam
/// uniform([])
/// ```
/// 
/// In which case it would be impossible to actually produce any value: none was
/// provided!
/// 
/// ## Examples
/// 
/// Given the following type to model colors:
/// 
/// ```gleam
/// pub type Color {
///   Red
///   Green
///   Blue
/// }
/// ```
/// 
/// You could write a generator that returns each color with an equal
/// probability (~33%) each color like this:
/// 
/// ```gleam
/// let color = random.uniform(Red, [Green, Blue])
/// ```
/// 
pub fn uniform(first: a, others: List(a)) -> Generator(a) {
  weighted(#(1.0, first), list.map(others, pair.new(1.0, _)))
}

/// This function works exactly like `uniform` but will return an `Error(Nil)`
/// if the provided argument is an empty list since the generator wouldn't be
/// able to produce any value in that case.
/// 
/// It generates values from the given list with equal probability.
/// 
/// ## Examples
/// 
/// ```gleam
/// random.try_uniform([])
/// // -> Error(Nil)
/// ```
/// 
/// For example if you consider the following type definition to model color:
/// 
/// ```gleam
/// type Color {
///   Red
///   Green
///   Blue
/// }
/// ```
/// 
/// This call of `try_uniform` will produce a generator wrapped in an `Ok`:
/// 
/// ```gleam
/// let assert Ok(color_1) = random.try_uniform([Red, Green, Blue])
/// let color_2 = random.uniform(Red, [Green, Blue])
/// ```
/// 
/// The generators `color_1` and `color_2` will behave exactly the same.
/// 
pub fn try_uniform(options: List(a)) -> Result(Generator(a), Nil) {
  case options {
    [first, ..rest] -> Ok(uniform(first, rest))
    [] -> Error(Nil)
  }
}

/// Generates values from the given ones with a weighted probability.
/// 
/// This generator can guarantee to produce values since it always takes at
/// least one item (as its first argument); if it were to accept just a list of
/// options, it could be called like this:
/// 
/// ```gleam
/// weighted([])
/// ```
/// 
/// In which case it would be impossible to actually produce any value: none was
/// provided!
/// 
/// ## Examples
/// 
/// Given the following type to model the outcome of a coin flip:
/// 
/// ```gleam
/// pub type CoinFlip {
///   Heads
///   Tails
/// }
/// ```
/// 
/// You could write a generator for a loaded coin that lands on head 75% of the
/// times like this:
/// 
/// ```gleam
/// let loaded_coin = random.weighted(#(Heads, 0.75), [#(Tails, 0.25)])
/// ```
/// 
/// In this example the weights add up to 1, but you could use any number: the
/// weights get added up to a `total` and the probability of each option is its
/// `weight` / `total`.
/// 
pub fn weighted(first: #(Float, a), others: List(#(Float, a))) -> Generator(a) {
  let normalise = fn(pair) { float.absolute_value(pair.first(pair)) }
  let total = normalise(first) +. float.sum(list.map(others, normalise))
  map(float(0.0, total), get_by_weight(first, others, _))
}

/// This function works exactly like `weighted` but will return an `Error(Nil)`
/// if the provided argument is an empty list since the generator wouldn't be
/// able to produce any value in that case.
/// 
/// It generates values from the given list with a weighted probability.
/// 
/// ## Examples
/// 
/// ```gleam
/// random.try_weighted([])
/// // -> Error(Nil)
/// ```
/// 
/// For example if you consider the following type definition to model color:
/// 
/// ```gleam
/// type CoinFlip {
///   Heads
///   Tails
/// }
/// ```
/// 
/// This call of `try_weighted` will produce a generator wrapped in an `Ok`:
/// 
/// ```gleam
/// let assert Ok(coin_1) =
///   random.try_weighted([#(0.75, Heads), #(0.25, Tails)])
/// let coin_2 = random.uniform(#(0.75, Heads), [#(0.25, Tails)])
/// ```
/// 
/// The generators `coin_1` and `coin_2` will behave exactly the same.
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

/// Generates two values with equal probability.
/// 
/// This is a shorthand for `random.uniform(one, [other])`, but can read better
/// when there's only two choices.
/// 
/// ## Examples
/// 
/// Given the following type to model the outcome of a coin flip:
/// 
/// ```gleam
/// pub type CoinFlip {
///   Heads
///   Tails
/// }
/// ```
/// 
/// You can write a generator for coin flip outcomes like this:
/// 
/// ```gleam
/// let flip = random.choose(Heads, Tails)
/// ```
/// 
pub fn choose(one: a, or other: a) -> Generator(a) {
  uniform(one, [other])
}

// DATA STRUCTURES -------------------------------------------------------------

/// Generates pairs of values obtained by combining the values produced by the
/// given generators.
/// 
/// ## Examples
/// 
/// ```gleam
/// let one_to_five = random.int(1, 5)
/// let probability = random.float(0.0, 1.0)
/// let ints_and_floats = random.pair(one_to_five, probability)
/// 
/// random.sample(ints_and_floats)
/// // -> #(3, 0.22)
/// ```
/// 
pub fn pair(one: Generator(a), with other: Generator(b)) -> Generator(#(a, b)) {
  map2(one, other, with: pair.new)
}

/// Generates a lists of a fixed size; its values are generated using the
/// given generator.
/// 
/// ## Examples
/// 
/// Imagine you're modelling a game of
/// [Risk](https://en.wikipedia.org/wiki/Risk_(game)); when a player "attacks"
/// they can roll three dice. You may model that outcome using `list` like this:
/// 
/// ```gleam
/// let dice_roll = random.int(1, 6)
/// let attack_outcome = random.list(dice_roll, 3)
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
      let #(value, seed) = step(generator, seed)
      do_list([value, ..acc], seed, generator, length - 1)
    }
  }
}

// MAPPING ---------------------------------------------------------------------

/// Transforms a generator into another one based on its generated values.
///
/// The random value generated by the given generator is fed into the `do`
/// function and the returned generator is used as the new generator.
/// 
/// ## Examples
/// 
/// `then` is a really powerful function, almost all functions exposed by this
/// library could be defined in term of it!
/// Take as an example `map`, it can be implemented like this:
/// 
/// ```gleam
/// fn map(generator: Generator(a), with fun: fn(a) -> b) -> Generator(b) {
///   random.then(generator, fn(value) {
///     random.constant(fun(value))
///   })
/// }
/// ```
/// 
/// Notice how the `do` function needs to return a `Generator(b)`, you can
/// achieve that by wrapping any constant value with the `random.constant`
/// generator.
/// 
/// > Code written with `then` can gain a lot in readability if you use the
/// > `use` syntax, especially if it has some deep nesting. As an example, this
/// > is how you can rewrite the previous example taking advantage of `use`:
/// >
/// > ```gleam
/// > fn map(generator: Generator(a), with fun: fn(a) -> b) -> Generator(b) {
/// >   use value <- random.then(generator)
/// >   random.constant(fun(value))
/// > }
/// > ```
/// 
pub fn then(
  generator: Generator(a),
  do generator_from: fn(a) -> Generator(b),
) -> Generator(b) {
  use seed <- Generator
  let #(value, seed) = step(generator, seed)
  generator_from(value)
  |> step(seed)
}

/// Transforms the values produced by a generator using the given function.
/// 
/// ## Examples
/// 
/// Imagine you want to make a generator for boolean values that returns
/// `True` and `False` with the same probability. You could do that using `map`
/// like this:
/// 
/// ```gleam
/// let bool_generator = random.int(1, 2) |> random.map(fn(n) { n == 1 })
/// ```
/// 
/// Here `map` allows you to transform the values produced by the initial
/// integer generator - either 1 or 2 - into boolean values: when the original
/// generator produces a 1, `bool_generator` will produce `True`; when the
/// original generator produces a 2, `bool_generator` will produce `False`.
/// 
pub fn map(generator: Generator(a), with fun: fn(a) -> b) -> Generator(b) {
  use seed <- Generator
  let #(value, seed) = step(generator, seed)
  #(fun(value), seed)
}

/// Combines two generators into a single one. The resulting generator produces
/// values obtained by applying `fun` to the values generated by the given
/// generators.
/// 
/// ## Examples
/// 
/// Imagine you need to generate random points in a 2D space:
/// 
/// ```gleam
/// pub type Point {
///   Point(x: Float, y: Float)
/// }
/// ```
/// 
/// You can compose two basic generators into a `Point` generator using `map2`:
/// 
/// ```gleam
/// let x_generator = random.float(-1.0, 1.0)
/// let y_generator = random.float(-1.0, 1.0)
/// let point_generator = map2(x_generator, y_generator, Point)
/// ```
/// 
/// > Notice how you could get the same result using `then`:
/// > 
/// > ```gleam
/// > pub fn point_generator() -> Generator(Point) {
/// >   use x <- random.then(random.float(-1.0, 1.0))
/// >   use y <- random.then(random.float(-1.0, 1.0))
/// >   random.constant(Point(x, y))
/// > }
/// > ```
/// >
/// > the `use` syntax paired with `then` may be confusing for other people
/// > reading your code, especially Gleam newcomers.
/// >
/// > Usually `map2`/`map3`/... will be more than enough if you just need to
/// > combine simple generators into more complex ones.
/// 
pub fn map2(
  one: Generator(a),
  other: Generator(b),
  with fun: fn(a, b) -> c,
) -> Generator(c) {
  use seed <- Generator
  let #(a, seed) = step(one, seed)
  let #(b, seed) = step(other, seed)
  #(fun(a, b), seed)
}

/// Combines three generators into a single one. The resulting generator
/// produces values obtained by applying `fun` to the values generated by the
/// given generators.
/// 
/// ## Examples
/// 
/// Imagine you're writing a generator for random enemies in a game you're
/// making:
/// 
/// ```gleam
/// pub type Enemy {
///   Enemy(health: Int, attack: Int, defense: Int)
/// }
/// ```
/// 
/// Each enemy starts with a random health (that can go from 50 to 100) and
/// random values for the `attack` and `defense` stats (each can be in a range
/// from 1 to 5):
/// 
/// ```gleam
/// let health_generator = random.int(50, 100)
/// let attack_generator = random.int(1, 5)
/// let defense_generator = random.int(1, 5)
/// 
/// let enemy_generator =
///   random.map3(
///     health_generator,
///     attack_generator,
///     defense_generator,
///     Enemy,
///   )
/// ```
/// 
pub fn map3(
  one: Generator(a),
  two: Generator(b),
  three: Generator(c),
  with fun: fn(a, b, c) -> d,
) -> Generator(d) {
  use seed <- Generator
  let #(a, seed) = step(one, seed)
  let #(b, seed) = step(two, seed)
  let #(c, seed) = step(three, seed)
  #(fun(a, b, c), seed)
}

/// Combines four generators into a single one. The resulting generator
/// produces values obtained by applying `fun` to the values generated by the
/// given generators.
/// 
pub fn map4(
  one: Generator(a),
  two: Generator(b),
  three: Generator(c),
  four: Generator(d),
  with fun: fn(a, b, c, d) -> e,
) -> Generator(e) {
  use seed <- Generator
  let #(a, seed) = step(one, seed)
  let #(b, seed) = step(two, seed)
  let #(c, seed) = step(three, seed)
  let #(d, seed) = step(four, seed)
  #(fun(a, b, c, d), seed)
}

/// Combines five generators into a single one. The resulting generator
/// produces values obtained by applying `fun` to the values generated by the
/// given generators.
/// 
/// > There's no `map6`, `map7`, and so on. If you feel like you need to compose
/// > together even more generators, you can use the `random.then` function.
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
  let #(a, seed) = step(one, seed)
  let #(b, seed) = step(two, seed)
  let #(c, seed) = step(three, seed)
  let #(d, seed) = step(four, seed)
  let #(e, seed) = step(five, seed)
  #(fun(a, b, c, d, e), seed)
}
