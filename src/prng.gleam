import gleam/io
import prng/random
import prng/seed

pub fn main() {
  let dice_roll = random.int(1, 6)
  let ten_rolls = random.list(dice_roll, 10)

  let #(result, _) = random.step(ten_rolls, seed.new(11))
  io.debug(result)
}
