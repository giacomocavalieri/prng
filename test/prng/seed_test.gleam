import gleeunit/should
import prng/seed

pub fn new_seed_test() {
  let seed = seed.new(11)

  seed.to_int(seed)
  |> should.equal(789_134_972)
}
