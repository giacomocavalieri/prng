pub type Seed

@external(erlang, "../ffi.erlang", "seed_to_int")
@external(javascript, "../ffi.mjs", "seed_to_int")
pub fn to_int(seed: Seed) -> Int

@external(erlang, "../ffi.erlang", "new_seed")
@external(javascript, "../ffi.mjs", "new_seed")
pub fn new(int: Int) -> Seed
