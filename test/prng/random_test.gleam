import gleam/dict
import gleam/iterator
import gleam/list
import gleam/set
import gleeunit/should
import prng/random.{type Generator}
import prng/seed

fn do_test(for_all generator: Generator(a), that property: fn(a) -> Bool) -> Nil {
  let number_of_samples = 1000
  let samples =
    random.to_random_iterator(generator)
    |> iterator.take(number_of_samples)
    |> iterator.to_list

  // The iterator should be infinite, so we _must_ always have 1000 samples
  list.length(samples)
  |> should.equal(number_of_samples)

  // Check that all generated values respect the given property
  list.all(samples, property)
  |> should.equal(True)
}

fn behaves_the_same(gen1: Generator(a), gen2: Generator(a)) -> Nil {
  let seed =
    random.int(random.min_int, random.max_int)
    |> random.map(seed.new)
    |> random.random_sample

  let samples1 =
    random.to_iterator(gen1, seed)
    |> iterator.take(1000)
    |> iterator.to_list
  let samples2 =
    random.to_iterator(gen2, seed)
    |> iterator.take(1000)
    |> iterator.to_list

  should.equal(samples1, samples2)
}

fn is_between(lower: Int, number: Int, upper: Int) -> Bool {
  lower <= number && number <= upper
}

pub fn is_between_f(lower: Float, number: Float, upper: Float) -> Bool {
  lower <=. number && number <=. upper
}

pub fn int_is_always_in_the_specified_range_test() {
  do_test(for_all: random.int(11, 11), that: fn(n) { n == 11 })
  do_test(for_all: random.int(-10, 10), that: is_between(-10, _, 10))
}

pub fn float_is_always_in_the_specified_range_test() {
  do_test(for_all: random.float(11.0, 11.0), that: fn(n) { n == 11.0 })
  do_test(for_all: random.float(-10.0, 10.0), that: is_between_f(-10.0, _, 10.0))
}

pub fn constant_always_returns_the_same_value_test() {
  do_test(for_all: random.constant(11), that: fn(n) { n == 11 })
}

pub fn map_returns_the_mapped_value_test() {
  let cool_people = random.map(random.int(1, 2), fn(_) { "Louis" })
  do_test(for_all: cool_people, that: fn(name) { name == "Louis" })
}

pub fn weighted_never_returns_value_with_zero_weight_test() {
  let languages = random.weighted(#(1.0, "Gleam"), [#(0.0, "TypeScript")])
  do_test(for_all: languages, that: fn(language) { language == "Gleam" })
}

pub fn fixed_size_list_generates_lists_of_the_given_length_test() {
  let empty_lists = random.fixed_size_list(random.constant(11), of: 0)
  do_test(for_all: empty_lists, that: fn(list) { list.is_empty(list) })

  let empty_lists = random.fixed_size_list(random.constant(11), of: -1)
  do_test(for_all: empty_lists, that: fn(list) { list.is_empty(list) })

  let lists = random.fixed_size_list(random.constant(11), of: 10)
  use list <- do_test(for_all: lists)
  list.length(list) == 10 && list.all(list, fn(n) { n == 11 })
}

pub fn list_returns_list_in_range_0_32_test() {
  use list <- do_test(for_all: random.list(random.int(1, 10)))
  let length = list.length(list)
  0 <= length && length <= 32
}

pub fn fixed_size_dict_generates_maps_of_at_most_the_given_length_test() {
  let keys = random.string()
  let values = random.int(1, 10)

  let empty_maps = random.fixed_size_dict(keys, values, of: 0)
  do_test(for_all: empty_maps, that: fn(map) { list.is_empty(dict.keys(map)) })

  let empty_maps = random.fixed_size_dict(keys, values, of: -1)
  do_test(for_all: empty_maps, that: fn(map) { list.is_empty(dict.keys(map)) })

  let maps = random.fixed_size_dict(keys, values, of: 10)
  use map <- do_test(for_all: maps)
  let length = list.length(dict.keys(map))
  0 < length && length <= 10
}

pub fn dict_returns_maps_in_range_0_32_test() {
  use map <- do_test(for_all: random.dict(random.string(), random.int(1, 10)))
  let length = list.length(dict.keys(map))
  0 <= length && length <= 32
}

pub fn fixed_size_set_generates_sets_of_at_most_the_given_length_test() {
  let values = random.string()

  let empty_sets = random.fixed_size_set(values, of: 0)
  do_test(for_all: empty_sets, that: fn(set) { set.size(set) == 0 })

  let empty_sets = random.fixed_size_set(values, of: -1)
  do_test(for_all: empty_sets, that: fn(set) { set.size(set) == 0 })

  let sets = random.fixed_size_set(values, of: 10)
  use set <- do_test(for_all: sets)
  let size = set.size(set)
  0 < size && size <= 10
}

pub fn set_returns_sets_in_range_0_32_test() {
  use set <- do_test(for_all: random.set(random.string()))
  let size = set.size(set)
  0 <= size && size <= 32
}

pub fn uniform_generates_values_from_the_given_list_test() {
  let examples = random.uniform(1, [2, 3])
  do_test(for_all: examples, that: fn(n) { n == 1 || n == 2 || n == 3 })
}

pub fn then_returns_the_new_generator_test() {
  let examples =
    random.constant(11)
    |> random.then(fn(n) {
      should.equal(n, 11)
      random.constant(12)
    })

  do_test(for_all: examples, that: fn(n) { n == 12 })
}

pub fn map_maps_the_generated_value_test() {
  let examples =
    random.constant(11)
    |> random.map(fn(n) {
      should.equal(n, 11)
      n + 1
    })

  do_test(for_all: examples, that: fn(n) { n == 12 })
}

pub fn map_behaves_the_same_as_then_and_constant_test() {
  let numbers = random.int(random.min_int, random.max_int)
  let gen1 = random.map(numbers, fn(n) { n + 1 })
  let gen2 = random.then(numbers, fn(n) { random.constant(n + 1) })
  behaves_the_same(gen1, gen2)
}

pub fn pair_behaves_the_same_as_map2_test() {
  let numbers = random.int(random.min_int, random.max_int)
  let gen1 = random.pair(numbers, numbers)
  let gen2 = random.map2(numbers, numbers, fn(m, n) { #(m, n) })
  behaves_the_same(gen1, gen2)
}

pub fn choose_behaves_the_same_as_uniform_test() {
  let gen1 = random.choose(1, 2)
  let gen2 = random.uniform(1, [2])
  behaves_the_same(gen1, gen2)
}

pub fn uniform_behaves_like_weighted_when_all_weights_are_equal_test() {
  let gen1 = random.uniform("Luois", ["Glob", "Hayleigh", "Ben"])
  let gen2 =
    random.weighted(#(2.2, "Luois"), [
      #(2.2, "Glob"),
      #(2.2, "Hayleigh"),
      #(2.2, "Ben"),
    ])
  behaves_the_same(gen1, gen2)
}

pub fn uniform_behaves_like_try_uniform_test() {
  let gen1 = random.uniform(1, [2])
  let assert Ok(gen2) = random.try_uniform([1, 2])
  behaves_the_same(gen1, gen2)
}

pub fn weighted_behaves_like_try_weighted_test() {
  let gen1 = random.weighted(#(1.0, 1), [#(2.0, 2)])
  let assert Ok(gen2) = random.try_weighted([#(1.0, 1), #(2.0, 2)])
  behaves_the_same(gen1, gen2)
}

pub fn constant_behaves_the_same_as_constant_map_test() {
  let gen1 = random.constant(11)
  let gen2 =
    random.map(random.int(random.min_int, random.max_int), fn(_) { 11 })
  behaves_the_same(gen1, gen2)
}

pub fn map2_maps_the_generated_value_test() {
  let assert [gen1, gen2] = list.map([1, 2], random.constant)
  let examples = random.map2(gen1, gen2, fn(a, b) { #(a, b) })
  do_test(for_all: examples, that: fn(value) { value == #(1, 2) })
}

pub fn map3_maps_the_generated_value_test() {
  let assert [gen1, gen2, gen3] = list.map([1, 2, 3], random.constant)
  let examples = random.map3(gen1, gen2, gen3, fn(a, b, c) { #(a, b, c) })
  do_test(for_all: examples, that: fn(value) { value == #(1, 2, 3) })
}

pub fn map4_maps_the_generated_value_test() {
  let assert [gen1, gen2, gen3, gen4] = list.map([1, 2, 3, 4], random.constant)
  let examples =
    random.map4(gen1, gen2, gen3, gen4, fn(a, b, c, d) { #(a, b, c, d) })
  do_test(for_all: examples, that: fn(value) { value == #(1, 2, 3, 4) })
}

pub fn map5_maps_the_generated_value_test() {
  let assert [gen1, gen2, gen3, gen4, gen5] =
    list.map([1, 2, 3, 4, 5], random.constant)
  let examples =
    random.map5(gen1, gen2, gen3, gen4, gen5, fn(a, b, c, d, e) {
      #(a, b, c, d, e)
    })
  do_test(for_all: examples, that: fn(value) { value == #(1, 2, 3, 4, 5) })
}

pub fn a_fixed_size_string_of_size_0_is_the_empty_string_test() {
  use string <- do_test(for_all: random.fixed_size_string(0))
  string == ""
}

import gleam/io

pub fn prova_test() {
  random.string()
  |> random.random_sample
  |> io.debug
}
