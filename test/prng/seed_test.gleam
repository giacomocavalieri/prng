import gleeunit/should
import prng/seed
import gleam/io

pub fn new_seed_test() {
  let seed =
    seed.new(11)
    |> io.debug

  seed.to_int(seed)
  |> should.equal(789_134_972)
}
