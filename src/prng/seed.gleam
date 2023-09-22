pub type Seed

@external(erlang, "ffi", "seed_to_int")
@external(javascript, "../ffi.mjs", "seed_to_int")
pub fn to_int(seed: Seed) -> Int

@external(erlang, "ffi", "new_seed")
@external(javascript, "../ffi.mjs", "new_seed")
pub fn new(int: Int) -> Seed
