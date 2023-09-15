import gleam/int
import prng/internals/int_32

pub opaque type Seed {
  Seed(state: Int, step: Int)
}

pub fn next(seed: Seed) -> Seed {
  let Seed(state, step) = seed
  let new_state = int_32.truncate(state * 1_664_525 + step)
  Seed(new_state, step)
}

pub fn to_int(seed: Seed) -> Int {
  let Seed(state, ..) = seed
  let word =
    int_32.unsigned_shift_right(state, by: 28) + 4
    |> int_32.unsigned_shift_right(state, by: _)
    |> int_32.xor(state)
    |> int.multiply(277_803_737)

  int_32.unsigned_shift_right(word, by: 22)
  |> int_32.xor(word)
  |> int_32.truncate
}

pub fn new(from: Int) -> Seed {
  let Seed(state, step) = next(Seed(0, 1_013_904_223))
  let new_state = int_32.truncate(state + from)
  next(Seed(new_state, step))
}
