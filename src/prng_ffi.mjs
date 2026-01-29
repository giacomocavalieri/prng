// A seed is just a pair [state, step]

export function new_seed(from) {
  const state = next(0);
  const new_state = (state + from) >>> 0;
  return next(new_state);
}

const step = 1_013_904_223;

function next(seed) {
  return (seed * 1_664_525 + step) >>> 0;
}

function seed_to_int(seed) {
  const shifted_state = seed >>> ((seed >>> 28) + 4);
  const word = (seed ^ shifted_state) * 277_803_737;
  return ((word >>> 22) ^ word) >>> 0;
}

export function random_int(seed, from, to) {
  const range = to - from + 1;
  const is_power_of_2 = ((range - 1) & range) === 0;
  if (is_power_of_2) {
    const number = ((range - 1) & seed_to_int(seed)) >>> 0;
    return [number + from, next(seed)];
  } else {
    const threshold = (-range >>> 0) % range >>> 0;
    let iteration_seed = seed;
    let x = undefined;
    do {
      x = seed_to_int(iteration_seed);
      iteration_seed = next(iteration_seed);
    } while (x < threshold);
    return [from + (x % range), iteration_seed];
  }
}

export function random_float(seed, from, to) {
  const new_seed = next(seed);
  const first_number = seed_to_int(seed);
  const second_number = seed_to_int(new_seed);

  const high = 0x03ffffff & first_number;
  const low = 0x07ffffff & second_number;
  const value = (high * 134217728.0 + low) / 9007199254740992.0;

  const range = to - from;
  const scaled = value * range + from;
  return [scaled, next(new_seed)];
}
