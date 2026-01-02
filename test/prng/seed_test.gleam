import gleeunit/should
import prng/random
import prng/seed

pub fn roundtrip_test() {
  let random_seed = seed.random()
  let encoded_seed = seed.encode_seed(random_seed)
  let decoded_seed = seed.decode_seed(encoded_seed)
  
  let generator = random.int(1, 6)
  
  let #(left_value, _random_next_seed) = random.step(generator, random_seed)
  let #(right_value, _new_next_seed) = random.step(generator, decoded_seed)
  
  should.equal(left_value, right_value)
}

pub fn continuation_test() {
  let random_seed = seed.random()
  
  let generator = random.int(1, 6)
  
  let #(_value, next_seed) = random.step(generator, random_seed)
  
  let encoded_seed = seed.encode_seed(next_seed)
  let decoded_seed = seed.decode_seed(encoded_seed)
  
  let #(left_value, _next_seed2) = random.step(generator, next_seed)
  let #(right_value, _next_seed3) = random.step(generator, decoded_seed)
  
  should.equal(left_value, right_value)
}