import gleam/bitwise

/// Truncates a number to 32 bits by taking its 32 least significant bits
/// (those furthest to the right).
///
/// ## Examples
/// 
/// ```gleam
/// truncate_to_32_bits(1)
/// // -> 1
/// 
/// truncate_to_32_bits(4_294_967_295) // 2^32 - 1
/// // -> 4_294_967_295
/// 
/// truncate_to_32_bits(4_294_967_296) // 2^32
/// // -> 0
/// ```
/// 
@external(javascript, "../../ffi.mjs", "truncate")
pub fn truncate(number: Int) -> Int {
  let <<truncated:size(32)>> = <<number:size(32)>>
  truncated
}

@external(javascript, "../../ffi.mjs", "unsigned_shift_right")
pub fn unsigned_shift_right(number: Int, by shift: Int) -> Int {
  let diff = 32 - shift
  let <<remaining:size(diff), _dropped:size(shift)>> = <<truncate(number):32>>
  remaining
}

pub fn xor(one: Int, other: Int) -> Int {
  truncate(bitwise.exclusive_or(one, other))
}
