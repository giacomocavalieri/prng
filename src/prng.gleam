import gleam/io
import prng/seed.{Seed}

pub fn main() {
  io.println("Hello from prng!")
}

pub fn seed(from: Int) -> Seed {
  todo
}

pub opaque type Generator(a) {
  Generator(step: fn(Seed) -> #(Seed, a))
}

pub fn step(generator: Generator(a), seed: Seed) -> #(Seed, a) {
  generator.step(seed)
}

pub fn constant(value: a) -> Generator(a) {
  use seed <- Generator
  #(seed, value)
}
