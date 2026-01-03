defmodule Daggerheart.DualityTest do
  use ExUnit.Case, async: true

  alias Daggerheart.Duality

  defp seq_roller(values) do
    ref = make_ref()
    Process.put(ref, values)

    fn _sides ->
      [h | t] = Process.get(ref)
      Process.put(ref, t)
      h
    end
  end

  test "roll_action/3 returns a Duality struct with valid ranges and types" do
    r = Duality.roll_action(2, 14, extra_mod: 1, advantage: true)

    assert is_struct(r, Duality)

    #Dice ranges

    assert r.hope_die in 1..12
    assert r.fear_die in 1..12

    # Advantage/disadvantage are nil or 1..6
    assert r.advantage_d6 == nil or r.advantage_d6 in 1..6
    assert r.disadvantage_d6 == nil or r.disadvantage_d6 in 1..6

    # Flags/types

    assert is_boolean(r.success?)
    assert is_boolean(r.critical?)

    assert r.with in [:hope, :fear]

    # Category is one of the known atoms
    assert r.category in [
        :critical_success,
        :success_with_hope,
        :success_with_fear,
        :failure_with_hope,
        :failure_with_fear
    ]

    # Deltas are integers
    assert is_integer(r.hope_delta)
    assert is_integer(r.fear_delta)

    # Mods are integers, difficulty positvie
    assert is_integer(r.trait_mod)
    assert is_integer(r.extra_mod)
    assert is_integer(r.difficulty) and r.difficulty > 0
  end

  test "total matches the documented formula" do
    # Deterministic: hope=8, fear=4, adv=5, dis=3
    roller = seq_roller([8,4,5,3])

    r =
      Duality.roll_action_test(-1,10, [extra_mod: 3, advantage: true, disadvantage: true], roller)

    adv = r.advantage_d6 || 0
    dis = r.disadvantage_d6 || 0

    expected =
      r.hope_die +
      r.fear_die +
      r.trait_mod +
      r.extra_mod +
      adv -
      dis

    assert r.total == expected
  end

  test "advantage flag controls advantage_d6 presence" do
    roller = seq_roller([8,4,6])
    r1 = Duality.roll_action_test(0, 10, [advantage: true], roller)

    assert r1.advantage_d6 in 1..6
    assert r1.disadvantage_d6 == nil

    roller2 = seq_roller([8,4])
    r2 = Duality.roll_action_test(0, 10, [advantage: false], roller2)
    assert r2.advantage_d6 == nil
  end

  test "disadvantage flag controls disadvantage_d6 presence" do
    roller = seq_roller([8,4,2])
    r1 = Duality.roll_action_test(0, 10, [disadvantage: true], roller)
    assert r1.advantage_d6 == nil
    assert r1.disadvantage_d6 in 1..6

    roller2 = seq_roller([8,4])
    r2 = Duality.roll_action_test(0, 10, [disadvantage: :false], roller2)
    assert r2.disadvantage_d6 == nil
  end

  test "critical implies success, category critical_success, with hope, hope_delta 1, fear_delta 1, clear_stress true" do
      roller = seq_roller([7,7]) # hope == fear => critical

      r = Duality.roll_action_test(0, 10, [], roller)

      assert r.success? == true
      assert r.category == :critical_success
      assert r.with == :hope
      assert r.hope_delta == 1
      assert r.fear_delta == 0
      assert r.clear_stress? == true
      assert r.hope_die == r.fear_die
  end

  test "success_with_hope when success and hope > fear" do
    roller = seq_roller([10, 5]) # total 15 vs diff 14

    r = Duality.roll_action_test(0, 14, [], roller)

    assert r.success? == true
    assert r.critical? == false
    assert r.category == :success_with_hope
    assert r.with == :hope
    assert r.hope_delta == 1
    assert r.fear_delta == 0
  end

  test "failure_with_fear when failure and fear > hope" do
    roller = seq_roller([2,9]) # total 11 vs diff 20

    r = Duality.roll_action_test(0, 20, [], roller)

    assert r.success? == false
    assert r.critical? == false
    assert r.category == :failure_with_fear
    assert r.with == :fear
    assert r.hope_delta == 0
    assert r.fear_delta == 1
  end



end
