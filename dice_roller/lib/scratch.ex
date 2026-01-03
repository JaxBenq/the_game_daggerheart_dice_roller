defmodule Scratch do
@moduledoc """
Simple functions for rolling dice.
"""

@doc """
Rolls a single die with 'sides' side.

## Examples

iex> DiceRoller.roll(6)
4
"""
def roll(sides) when is_integer(sides) and sides >0 do
  :rand.uniform(sides)
end

@doc """
Rolls 'count' dice with 'sides' sides.

## Example:
iex> DiceRoller.roll_many(3,6)
[2,3,5]
"""

def roll_many(counts, sides)
when is_integer(counts) and counts >0 and is_integer(sides) and sides >0 do
  Enum.map(1..counts, fn _ -> roll(sides) end)
end

@doc """
Rolls 'count' dice with 'sides' sides and returns the sum.

## Example:
iex> DiceRoller.roll_sum(3,6)
11
"""
def roll_sum(counts, sides) do
  roll_many(counts, sides)
  |>Enum.sum()
end

@doc """
Parses a dice expression like \"3d6\" and rolls it.
Returns {:ok, rolls, sum} or {:error, reason}.
"""

def roll_d(expr) when is_binary(expr) do
  case String.split(expr, "d") do
    [count_str, sides_str] ->
      with {count, ""} <- Integer.parse(count_str),
           {sides, ""} <- Integer.parse(sides_str),
           true <- count >0 and sides >0 do
             rolls = roll_many(count, sides)
             {:ok, rolls, Enum.sum(rolls)}
           else
            _ -> {:error, :invalid_numbers}
           end
           _ ->
            {:error, :invalid_format}
  end
end
end
