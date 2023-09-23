// A seed is just a pair [state, step]

export function new_seed(from) {
    const [state, step] = next([0, 1_013_904_223])
    const new_state = (state + from) >>> 0
    return next([new_state, step])
}

function next(seed) {
    const [state, step] = seed
    const new_state = ((state * 1_664_525) + step) >>> 0
    return [new_state, step]
}

export function seed_to_int(seed) {
    const [state, _step] = seed
    const shifted_state = state >>> ((state >>> 28) + 4)
    const word = (state ^ shifted_state) * 277_803_737
    return ((word >>> 22) ^ word) >>> 0
}

export function random_int(seed, low, high) {
    const range = high - low + 1 // 32
    const is_power_of_2 = ((range - 1) & range) === 0
    if (is_power_of_2) {
        const number = ((range - 1) & seed_to_int(seed)) >>> 0
        return [number + low, next(seed)]
    } else {
        const threshold = (((-range) >>> 0) % range) >>> 0
        let iteration_seed = seed
        let x = undefined
        do {
            x = seed_to_int(iteration_seed)
            iteration_seed = next(seed)
        } while (x < threshold)
        return [low + (x % range), iteration_seed]
    }
}
