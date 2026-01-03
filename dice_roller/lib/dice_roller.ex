defmodule DiceRoller do
  @moduledoc """
  Simple functions for rolling dice.
  """

  @doc """
  Rolls a single die with 'sides' side.

  ## Examples

      iex> DiceRoller.roll(6)
      4

  """
  def roll(sides) when is_integer(sides) and sides > 0 do
    :rand.uniform(sides)
    end


  @doc """
  Rolls 'count' dice with 'sides' sides.

  Returns a list of individual rolls.

  Example:
    iex> DiceRoller.roll_many(3,6)
    [2,6,4]
  """
  def roll_many(count, sides)
   when is_integer(count) and count > 0 and is_integer(sides) and sides > 0 do
     Enum.map(1..count, fn _ -> roll(sides) end)
   end

   @doc """
   Rolls 'count' dice with 'sides' sides and returns the sum.

   Example:
    iex> DiceRoller.roll_sum(3,6)
    11
  """

  def roll_sum(count, sides) do
    roll_many(count, sides)
    |> Enum.sum()
  end

  @doc """
  Parses a dice expression like \"3d6\" and rolls it.

  Returns {:ok, rolls, sum} or {:error, reason}.
  """

  def roll_dices(expr) when is_binary(expr) do
    case String.split(expr, "d") do
      [count_str, sides_str] ->
        with {count, ""} <- Integer.parse(count_str),
             {sides, ""} <- Integer.parse(sides_str),
             true <- count > 0 and sides > 0 do
              rolls = roll_many(count, sides)
              {:ok, rolls, Enum.sum(rolls)}
        else
          _ -> {:error, :invalid_numbers}
        end
      _ ->
        {:error, :invalid_format}
    end
  end

  @doc """
  Roll with flags, returns {:critical, value} if rolled a 20, {:normal, value} for other rolls
  """
  def roll_with_flags(sides) do
    value = roll(sides)
    roll_with_flags(value, sides)
  end

  #critical case
  defp roll_with_flags(value, value), do: {:critical, value}

  #normal case
  defp roll_with_flags(value, _sides), do: {:normal, value}

  @doc """
  Performs a simple check: success if roll > sides / 2, else fail.

  Returns `{:success, value}` or `{:fail, value}`.
  """
  def roll_check(sides) do
    threshold = div(sides,2)
    value = roll(sides)
    roll_check(threshold, value)

  end

  defp roll_check(threshold, value) when value > threshold, do: {:success, value}

  defp roll_check(_threshold, value), do: {:fail, value}

  @doc """
  Rolls with advantage: roll twice, keep the higher.

  Returns '{best, {first, second}}'.
  """
  def roll_adv(sides) when is_integer(sides) and sides > 0 do
    roll1 = roll(sides)
    roll2 = roll(sides)
    best = max(roll1, roll2)
    {best, {roll1, roll2}}
  end

  @doc """
  Rolls with disadvantage: roll twice, keep the lower.

  Retunrs '{worst, {first, second}}'.
  """

  def roll_dis(sides) when is_integer(sides) and sides > 0 do
    roll1 = roll(sides)
    roll2 = roll(sides)
    worst = min(roll1, roll2)
    {worst, {roll1, roll2}}
  end

  @doc """
  Rolls one with crit flag; if it's a critical (max value),
  performs a second roll to confirm.

  Returns:
    *'{:normal, value}' for non-crit
    *'{:critical, value, confirm}' for crits
  """

  def roll_with_confirm(sides) when is_integer(sides) and sides > 0 do
    {flag, value} = roll_with_flags(sides)

    case flag do
      :critical ->
          confirm = roll(sides)
          {:critical, value, confirm}
      :normal ->
        {:normal, value}
    end
  end
end
