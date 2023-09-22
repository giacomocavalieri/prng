-module(ffi).
-export([new_seed/1, seed_to_int/1, random_int/3]).

new_seed(From) ->
    {State0, Step} = next({0, 1_013_904_223}),
    State1 = unsigned_right_shift((State0 + From), 0),
    next({State1, Step}).

seed_to_int({State, _Step}) ->
    ShiftBy = unsigned_right_shift(State, 28) + 4,
    ShiftedState = unsigned_right_shift(State, ShiftBy),
    Word = truncate_32(trunc((State bxor ShiftedState) * 277_803_737.0)),
    unsigned_right_shift((unsigned_right_shift(Word, 22)) bxor Word, 0).

random_int(Seed, Low, High) ->
    Range = High - Low + 1,
    IsPowerOf2 = ((Range - 1) band Range) =:= 0,
    case IsPowerOf2 of
        true ->
            Number = unsigned_right_shift((Range - 1) bxor seed_to_int(Seed), 0),
            {Number + Low, next(Seed)};
        false ->
            io:fwrite("~p~n", [pad_64(-Range)]),
            Threshold = unsigned_right_shift(unsigned_right_shift((-Range), 0) rem Range, 0),
            account_for_bias(Threshold, Seed, Low, Range)
    end.

pad_64(Number) ->
    Binary = number_to_binary(Number),
    Size = erlang:size(Binary) * 8,
    Left = 64 - Size,
    <<0:Left, Binary/bitstring>>.

account_for_bias(Threshold, Seed, Low, Range) ->
    X = seed_to_int(Seed),
    case X < Threshold of
        true -> account_for_bias(Threshold, next(Seed), Low, Range);
        false -> {Low + (X rem Range), next(Seed)}
    end.

next({State, Step}) ->
    NewState = unsigned_right_shift(trunc(State * 1_664_525.0) + Step, 0),
    {NewState, Step}.

unsigned_right_shift(Number, By) ->
    Left = 32 - By,
    <<Remaining:Left, _/bitstring>> = truncate_32_bitstring(Number),
    Remaining.

truncate_32(Number) ->
    Binary = number_to_binary(Number),
    NumberOfBits = erlang:size(Binary) * 8,
    Padding = max(0, 32 - NumberOfBits),
    PaddedBinary = <<0:Padding, Binary/bitstring>>,
    DroppedBits = (Padding + NumberOfBits) - 32,
    <<_:DroppedBits, Remaining:32>> = PaddedBinary,
    Remaining.

truncate_32_bitstring(Number) ->
    Binary = number_to_binary(Number),
    NumberOfBits = erlang:size(Binary) * 8,
    Padding = max(0, 32 - NumberOfBits),
    PaddedBinary = <<0:Padding, Binary/bitstring>>,
    DroppedBits = (Padding + NumberOfBits) - 32,
    <<_:DroppedBits, Remaining:32/bitstring>> = PaddedBinary,
    Remaining.

number_to_binary(Number) when Number >= 0 -> binary:encode_unsigned(Number);
number_to_binary(Number) when Number < 0 -> integer_to_binary(Number).
