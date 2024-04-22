-module(prng_ffi).
-export([new_seed/1, seed_to_int/1, random_int/3, random_float/3]).

new_seed(From) ->
    {State0, Step} = next({0, 1_013_904_223}),
    State1 = truncate_32(State0 + From),
    next({State1, Step}).

seed_to_int({State, _Step}) ->
    ShiftedState = urs(State, urs(State, 28) + 4),
    Word = trunc(expand_to_64(State bxor ShiftedState) * 277_803_737.0),
    truncate_32(urs(Word, 22) bxor Word).

random_float(Seed, From, To) ->
    NewSeed = next(Seed),
    FirstNumber = seed_to_int(Seed),
    SecondNumber = seed_to_int(NewSeed),
    High = FirstNumber band 16#03FFFFFF,
    Low = SecondNumber band 16#07FFFFFF,
    Value = ((High * 134217728.0) + Low) / 9007199254740992.0,
    Range = To - From,
    Scaled = Value * Range + From,
    {Scaled, next(NewSeed)}.

random_int(Seed, From, To) ->
    Range = To - From + 1,
    IsPowerOf2 = ((Range - 1) band Range) =:= 0,
    case IsPowerOf2 of
        true ->
            Number = truncate_32(seed_to_int(Seed) band (Range - 1)),
            {Number + From, next(Seed)};
        false ->
            Threshold = truncate_32(truncate_32(-Range) rem Range),
            account_for_bias(Threshold, Seed, From, Range)
    end.

account_for_bias(Threshold, Seed, From, Range) ->
    X = seed_to_int(Seed),
    IterationSeed = next(Seed),
    case X < Threshold of
        true ->
            account_for_bias(Threshold, IterationSeed, From, Range);
        false ->
            {From + (X rem Range), IterationSeed}
    end.

next({State, Step}) ->
    NewState = urs((State * 1_664_525.0) + Step, 0),
    {NewState, Step}.

% unsigned right shift
urs(Number, By) ->
    Left = 32 - By,
    <<Remaining:Left, _/bitstring>> = truncate_32(Number, to_bit),
    Remaining.

expand_to_64(Number) ->
    <<NumberBits:32/bitstring>> = <<Number:32/integer>>,
    <<First:1, _:31/bitstring>> = NumberBits,
    Pad =
        case First =:= 1 of
            true -> <<-1:32>>;
            false -> <<0:32>>
        end,
    <<Result:64/signed-integer>> = <<Pad/bitstring, NumberBits/bitstring>>,
    Result.

truncate_32(Number) -> truncate_32(Number, to_int).
truncate_32(Number, Mode) when is_float(Number) ->
    truncate_32(trunc(Number), Mode);
truncate_32(Number, to_int) ->
    Number band 4294967295;
truncate_32(Number, to_bit) ->
    Truncated = truncate_32(Number, to_int),
    <<Truncated:32/integer>>.
