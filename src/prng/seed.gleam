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

/// Encodes a seed.
///
@external(erlang, "prng_ffi", "encode_seed")
@external(javascript, "../prng_ffi.mjs", "encode_seed")
pub fn encode_seed(seed: Seed) -> String

/// Decodes a seed.
///
@external(erlang, "prng_ffi", "decode_seed")
@external(javascript, "../prng_ffi.mjs", "decode_seed")
pub fn decode_seed(seed: String) -> Seed