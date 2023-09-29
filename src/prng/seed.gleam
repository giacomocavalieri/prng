/// A seed is the value that is used by the random number generation algorithm
/// to come up with new pseudo-random values.
/// 
pub type Seed

/// Turns a seed into an integer based on its internal state.
/// 
@external(erlang, "ffi", "seed_to_int")
@external(javascript, "../ffi.mjs", "seed_to_int")
pub fn to_int(seed: Seed) -> Int

/// Creates a new seed from a given integer.
/// 
@external(erlang, "ffi", "new_seed")
@external(javascript, "../ffi.mjs", "new_seed")
pub fn new(int: Int) -> Seed
