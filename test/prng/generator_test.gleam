import gleeunit/should
import prng/seed
import prng/generator
import gleam/list
import gleam/map
import gleam/int
import gleam/io
import gleam/float

pub fn int_list_behaves_the_same_as_elm_implementation_test() {
  let seed = seed.new(11)
  let generator = generator.list(generator.int(1, 4), of: 1_000_000)
  let #(value, _seed) = generator.step(generator, seed)
  let groups = list.group(value, by: fn(x) { x })
  map.map_values(groups, fn(_, l) { list.length(l) })
  |> map.values
  |> list.map(fn(n) { int.to_float(n) /. 1_000_000.0 })
  |> float.sum
  |> io.debug

  should.equal(1, 2)
}
