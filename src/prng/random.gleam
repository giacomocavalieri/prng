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
////     <a href="#string">string</a>,
////     <a href="#fixed_size_string">fixed_size_string</a>,
////     <a href="#bit_array">bit_array</a>,
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
////     <a href="#pair">pair</a>
////   </td>
//// </tr>
//// <tr>
////   <td>Generating common data structures</td>
////   <td>
////     <a href="#fixed_size_list">fixed_size_list</a>,
////     <a href="#list">list</a>,
////     <a href="#fixed_size_dict">fixed_size_dict</a>,
////     <a href="#dict">dict</a>
////     <a href="#fixed_size_set">fixed_size_set</a>,
////     <a href="#set">set</a>
////   </td>
//// </tr>
//// <tr>
////   <td>Getting values out of a generator</td>
////   <td>
////     <a href="#step">step</a>
////   </td>
//// </tr>
//// </table>
////

import gleam/bit_array
import gleam/bool
import gleam/dict.{type Dict}
import gleam/float
import gleam/int
import gleam/list
import gleam/set.{type Set}
import gleam/string

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

/// A seed is the value that is used by the random number generation algorithm
/// to come up with new pseudo-random values.
///
pub type Seed

@external(erlang, "prng_ffi", "new_seed")
@external(javascript, "../prng_ffi.mjs", "new_seed")
pub fn new_seed(int: Int) -> Seed

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
/// try [`to_yielder`](#to_yielder),
/// [`to_random_yielder`](#to_random_yielder), or [`sample`](#sample) instead.
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
  case from <= to {
    True -> Generator(random_int(_, from, to))
    False -> Generator(random_int(_, to, from))
  }
}

@external(erlang, "prng_ffi", "random_int")
@external(javascript, "../prng_ffi.mjs", "random_int")
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
  case from <=. to {
    True -> Generator(random_float(_, from, to))
    False -> Generator(random_float(_, to, from))
  }
}

@external(erlang, "prng_ffi", "random_float")
@external(javascript, "../prng_ffi.mjs", "random_float")
fn random_float(seed: Seed, from: Float, to: Float) -> #(Float, Seed)

// PURE GLEAM BUILDERS ---------------------------------------------------------

/// Always generates the given value, no matter the seed used.
///
/// ## Examples
///
/// ```gleam
/// let always_eleven = random.constant(11)
/// random.random_sample(always_eleven)
/// // -> 11
/// ```
///
pub fn constant(value: a) -> Generator(a) {
  Generator(fn(seed) { #(value, seed) })
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
  weighted(#(1.0, first), list.map(others, fn(value) { #(1.0, value) }))
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
/// let loaded_coin = random.weighted(#(0.75, Heads), [#(0.25, Tails)])
/// ```
///
/// In this example the weights add up to 1, but you could use any number: the
/// weights get added up to a `total` and the probability of each option is its
/// `weight` / `total`.
///
pub fn weighted(first: #(Float, a), others: List(#(Float, a))) -> Generator(a) {
  let total = sum_absolute_values(others, float.absolute_value(first.0))
  map(float(0.0, total), get_by_weight(first, others, _))
}

fn sum_absolute_values(list: List(#(Float, a)), acc: Float) -> Float {
  case list {
    [] -> acc
    [#(value, _), ..rest] ->
      sum_absolute_values(rest, acc +. float.absolute_value(value))
  }
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
      case countdown >. positive_weight {
        False -> value
        True -> get_by_weight(second, rest, countdown -. positive_weight)
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
/// random.random_sample(ints_and_floats)
/// // -> #(3, 0.22)
/// ```
///
@deprecated("use `random.then` to compose multiple generators")
pub fn pair(one: Generator(a), with other: Generator(b)) -> Generator(#(a, b)) {
  use n <- then(one)
  use m <- then(other)
  constant(#(n, m))
}

/// Generates a lists of a fixed size; its values are generated using the
/// given generator.
///
/// ## Examples
///
/// Imagine you're modelling a game of
/// [Risk](https://en.wikipedia.org/wiki/Risk_(game)); when a player "attacks"
/// they can roll three dice. You may model that outcome using `fixed_size_list`
/// like this:
///
/// ```gleam
/// let dice_roll = random.int(1, 6)
/// let attack_outcome = random.fixed_size_list(dice_roll, 3)
/// ```
///
pub fn fixed_size_list(
  from generator: Generator(a),
  of length: Int,
) -> Generator(List(a)) {
  Generator(do_fixed_size_list([], _, generator, length))
}

fn do_fixed_size_list(
  acc: List(a),
  seed: Seed,
  generator: Generator(a),
  length: Int,
) -> #(List(a), Seed) {
  case length <= 0 {
    True -> #(acc, seed)
    False -> {
      let #(value, seed) = step(generator, seed)
      do_fixed_size_list([value, ..acc], seed, generator, length - 1)
    }
  }
}

/// Generates a list with a random size with at most 32 items.
/// Each item is generated using the given generator.
///
/// This is similar to `fixed_size_list` with the difference that the size
/// is chosen randomly.
///
pub fn list(generator: Generator(a)) -> Generator(List(a)) {
  // ⚠️ There might be a more thoughtful implementation that has higher chances
  // of returning empty lists (or shorter ones), for now I think this is more
  // than enough
  then(int(0, 32), fixed_size_list(from: generator, of: _))
}

/// Generates a `Dict(k, v)` where each key value pair is generated using the
/// provided generators.
///
/// > ⚠️ This function makes a best effort at generating a map with exactly the
/// > specified number of keys, but beware that it may contain less items if
/// > the keys generator cannot generate enough distinct keys.
///
pub fn fixed_size_dict(
  keys keys: Generator(k),
  values values: Generator(v),
  of size: Int,
) {
  int.max(size, 0)
  |> do_fixed_size_dict(keys, values, _, 0, 0, dict.new())
}

fn do_fixed_size_dict(
  keys: Generator(k),
  values: Generator(v),
  size: Int,
  unique_keys: Int,
  consecutive_attempts: Int,
  // ^-- this is the number of consecutive attempts at generating a key that
  //     doesn't already exist in the map we're generating
  acc: Dict(k, v),
) -> Generator(Dict(k, v)) {
  let has_required_size = unique_keys == size
  use <- bool.guard(when: has_required_size, return: constant(acc))

  let has_reached_maximum_attempts = consecutive_attempts >= 10
  use <- bool.guard(when: has_reached_maximum_attempts, return: constant(acc))
  // ^-- if after 10 tries, we couldn't still generate a key that doesn't
  //     already exist, then we give up and return a map smaller than required

  use key <- then(keys)
  case dict.has_key(acc, key) {
    True ->
      // ^-- if the key is already present in the map we can't add it and we
      //     increase the number of failed attempts at generating a distinct key
      do_fixed_size_dict(
        keys,
        values,
        size,
        unique_keys,
        consecutive_attempts + 1,
        acc,
      )

    False -> {
      // ^-- if we could indeed generate a new key, we set the number of failed
      //     attempts to zero and are ready to start again with a new one
      use value <- then(values)
      let unique_keys = unique_keys + 1
      let acc = dict.insert(acc, key, value)
      do_fixed_size_dict(keys, values, size, unique_keys, 0, acc)
    }
  }
}

/// Generates a `Map(k, v)` where each key value pair is generated using the
/// provided generators.
///
/// This is similar to `fixed_size_dict` with the difference that the map is
/// going to have a random number of key-value pairs between 0 (inclusive) and
/// 32 (inclusive).
///
pub fn dict(keys keys: Generator(k), values values: Generator(v)) {
  use size <- then(int(0, 32))
  fixed_size_dict(keys, values, size)
}

/// Generates a `Set(a)` where each item is generated using the provided
/// generator.
///
/// > ⚠️ This function makes a best effort at generating a set with exactly the
/// > specified number of items, but beware that it may contain less items if
/// > the given generator cannot generate enough distinct values.
///
pub fn fixed_size_set(
  from generator: Generator(a),
  of size: Int,
) -> Generator(Set(a)) {
  do_fixed_size_set(generator, int.max(size, 0), 0, 0, set.new())
}

fn do_fixed_size_set(
  generator: Generator(a),
  size: Int,
  unique_items: Int,
  consecutive_attempts: Int,
  // ^-- this is the number of consecutive attempts at generating a key that
  //     doesn't already exist in the map we're generating
  acc: Set(a),
) -> Generator(Set(a)) {
  let has_required_size = unique_items == size
  use <- bool.guard(when: has_required_size, return: constant(acc))

  let has_reached_maximum_attempts = consecutive_attempts >= 10
  use <- bool.guard(when: has_reached_maximum_attempts, return: constant(acc))
  // ^-- if after 10 tries, we couldn't still generate an item that doesn't
  //     already exist in the set, then we give up and return a set smaller than
  //     required

  use item <- then(generator)
  case set.contains(acc, item) {
    True ->
      // ^-- if the item is already present in the set we can't add it and we
      //     increase the number of failed attempts at generating a new item
      do_fixed_size_set(
        generator,
        size,
        unique_items,
        consecutive_attempts + 1,
        acc,
      )

    False -> {
      // ^-- if we could indeed generate a new item, we set the number of failed
      //     attempts to zero and are ready to start again with a new one
      let unique_items = unique_items + 1
      let acc = set.insert(acc, item)
      do_fixed_size_set(generator, size, unique_items, 0, acc)
    }
  }
}

/// Generates a `Set(a)` where each item is generated using the provided
/// generator.
///
/// This is similar to `fixed_size_set` with the difference that the set is
/// going to have a random size between 0 (inclusive) and 32 (inclusive).
///
pub fn set(generator: Generator(a)) -> Generator(Set(a)) {
  use size <- then(int(0, 32))
  fixed_size_set(from: generator, of: size)
}

/// Generates `BitArray`s with a random size.
///
pub fn bit_array() -> Generator(BitArray) {
  map(string(), bit_array.from_string)
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
  Generator(fn(seed) {
    let #(value, seed) = step(generator, seed)
    step(generator_from(value), seed)
  })
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
  Generator(fn(seed) {
    let #(value, seed) = step(generator, seed)
    #(fun(value), seed)
  })
}

/// Combines two generators into a single one. The resulting generator produces
/// values obtained by applying `fun` to the values generated by the given
/// generators.
///
/// ## Examples
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
@deprecated("use `random.then` to compose multiple generators")
pub fn map2(
  one: Generator(a),
  other: Generator(b),
  with fun: fn(a, b) -> c,
) -> Generator(c) {
  Generator(fn(seed) {
    let #(a, seed) = step(one, seed)
    let #(b, seed) = step(other, seed)
    #(fun(a, b), seed)
  })
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
@deprecated("use `random.then` to compose multiple generators")
pub fn map3(
  one: Generator(a),
  two: Generator(b),
  three: Generator(c),
  with fun: fn(a, b, c) -> d,
) -> Generator(d) {
  Generator(fn(seed) {
    let #(a, seed) = step(one, seed)
    let #(b, seed) = step(two, seed)
    let #(c, seed) = step(three, seed)
    #(fun(a, b, c), seed)
  })
}

/// Combines four generators into a single one. The resulting generator
/// produces values obtained by applying `fun` to the values generated by the
/// given generators.
///
@deprecated("use `random.then` to compose multiple generators")
pub fn map4(
  one: Generator(a),
  two: Generator(b),
  three: Generator(c),
  four: Generator(d),
  with fun: fn(a, b, c, d) -> e,
) -> Generator(e) {
  Generator(fn(seed) {
    let #(a, seed) = step(one, seed)
    let #(b, seed) = step(two, seed)
    let #(c, seed) = step(three, seed)
    let #(d, seed) = step(four, seed)
    #(fun(a, b, c, d), seed)
  })
}

/// Combines five generators into a single one. The resulting generator
/// produces values obtained by applying `fun` to the values generated by the
/// given generators.
///
/// > There's no `map6`, `map7`, and so on. If you feel like you need to compose
/// > together even more generators, you can use the `random.then` function.
///
@deprecated("use `random.then` to compose multiple generators")
pub fn map5(
  one: Generator(a),
  two: Generator(b),
  three: Generator(c),
  four: Generator(d),
  five: Generator(e),
  with fun: fn(a, b, c, d, e) -> f,
) -> Generator(f) {
  Generator(fn(seed) {
    let #(a, seed) = step(one, seed)
    let #(b, seed) = step(two, seed)
    let #(c, seed) = step(three, seed)
    let #(d, seed) = step(four, seed)
    let #(e, seed) = step(five, seed)
    #(fun(a, b, c, d, e), seed)
  })
}

// CHARACTERS AND STRINGS ------------------------------------------------------

/// Generates Strings with a random number of UTF code points, between
/// 0 (included) and 32 (included).
///
/// This is similar to `fixed_size_string`, with the difference that the
/// size is randomly generated as well.
///
pub fn string() -> Generator(String) {
  use size <- then(int(0, 32))
  fixed_size_string(size)
}

/// Generates Strings with the given number number of UTF code points.
///
/// > ⚠️ The generated codepoints will be in the range from 0 (inclusive) to
/// > 1023 (inclusive). If you feel like these strings are not enough for your
/// > needs, please open an issue! I'd love to hear your use case and improve
/// > the package.
///
pub fn fixed_size_string(size: Int) -> Generator(String) {
  fixed_size_list(from: utf_codepoint_in_range(0, 1023), of: size)
  |> map(string.from_utf_codepoints)
}

/// I'm not exposing this function because, if one is not careful with the range,
/// it might lead to a nasty infinite loop.
/// When I come up with a better alternative I might make a similar API public,
/// for now, if someone wants to do something unsafe they will have to
/// manually reimplement it.
///
fn utf_codepoint_in_range(lower: Int, upper: Int) -> Generator(UtfCodepoint) {
  use raw_codepoint <- then(int(lower, upper))
  case string.utf_codepoint(raw_codepoint) {
    Ok(codepoint) -> constant(codepoint)
    Error(_) -> utf_codepoint_in_range(lower, upper)
  }
  // ⚠️ ^-- this works under the assumption (which might be wrong!) that invalid
  //        unicode chars in the given range are pretty rare and we're not
  //        getting stuck in the recursion for a long time
}
