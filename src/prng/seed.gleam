import gleam/int

/// A seed is the value that is used by the random number generation algorithm
/// to come up with new pseudo-random values.
///
pub type Seed

/// Creates a new seed from a given integer.
///
@external(erlang, "prng_ffi", "new_seed")
@external(javascript, "../prng_ffi.mjs", "new_seed")
pub fn new(int: Int) -> Seed

/// Creates a new random seed. You can use it when you don't care about
/// having reproducible results and just need to get some values out of a
/// generator using the `random.step` function.
///
pub fn random() -> Seed {
  new(int.random(4_294_967_296))
}
