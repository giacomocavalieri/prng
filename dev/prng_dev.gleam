import prng/random

pub fn main() {
  // The readme example
  let generator = random.int(0, 10)
  let #(n, new_seed) = random.step(generator, random.new_seed(11))
  let #(m, _) = random.step(generator, new_seed)
  echo n
  echo m
}
