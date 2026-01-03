defmodule DiceRollerTest do
  alias GenLSP.Structures.ExecutionSummary
  use ExUnit.Case
  doctest DiceRoller

  test "roll/1 returns a number between 1 and sides" do
    for _ <- 1..50  do
      result = DiceRoller.roll(6)
      assert result >= 1
      assert result <= 6
    end
  end

  test "roll_many/2 returns the correct number of rolls" do
    rolls = DiceRoller.roll_many(5,10)
    assert length(rolls) == 5
    assert Enum.all?(rolls, fn r -> r >= 1 and r <=10 end)
  end

  test "roll_sum/2 sums roll_many/2 results" do
    sum = DiceRoller.roll_sum(3,6)
    assert sum >=3 and sum <=18
  end

  test "roll_dices parses expressions like '3d6'" do
    {:ok, rolls, sum} = DiceRoller.roll_dices("3d6")
    assert length(rolls) == 3
    assert Enum.sum(rolls) == sum
  end

  test "roll_with_flags marks max value as critical" do
    #Test by controlling RNG - simple approach:
    result = DiceRoller.roll_with_flags(1) #Only possible roll is 1
    assert result == {:critical, 1}
  end

  test "roll_check succeeds for values above threshold" do
    # threshold for d20 = 10
    assert {:success, 1} = DiceRoller.roll_check(1)
  end
end
