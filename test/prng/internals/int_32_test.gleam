import gleam/float
import gleam/int
import gleam/list
import gleeunit/should
import prng/internals/int_32

fn power(n: Int, of power: Int) -> Int {
  let assert Ok(power) = int.power(n, of: int.to_float(power))
  float.truncate(power)
}

pub fn max_number() -> Int {
  power(2, of: 32) - 1
}

pub fn truncate_to_32_bits_in_range_test() {
  use n <- list.each([0, 1, 10, 11, 32, 256, max_number()])
  int_32.truncate(n)
  |> should.equal(n)
}

pub fn truncate_to_32_bits_overflow_test() {
  use n <- list.each([1, 10, 11, 32, 256, max_number()])
  int_32.truncate(max_number() + n)
  |> should.equal(n - 1)
}

pub fn truncate_to_32_bits_negative_is_truncated_2_complement_test() {
  use n <- list.each([-1, -2, -11, -30, -256, -1024, -max_number()])
  int_32.truncate(n)
  |> should.equal(int_32.truncate(max_number() + n + 1))
}

pub fn shift_test_values() {
  [
    0,
    1,
    10,
    11,
    256,
    max_number(),
    max_number() + 11,
    max_number() * 2,
    -1,
    -10,
    -max_number(),
    -max_number() - 11,
    -max_number() * 2,
  ]
}

pub fn unsigned_shift_right_by_zero_equivalent_to_truncate_test() {
  use n <- list.each(shift_test_values())
  int_32.unsigned_shift_right(n, by: 0)
  |> should.equal(int_32.truncate(n))
}

pub fn unsigned_shift_right_equivalent_to_division_by_2_test() {
  use n <- list.each(shift_test_values())
  int_32.unsigned_shift_right(n, by: 1)
  |> should.equal(int_32.truncate(n) / 2)
}
