defmodule Daggerheart.CheckTest do
  use ExUnit.Case, async: true

  alias Daggerheart.{Check, Duality}

  test "new/4 sets fields and defaults" do
    c = Check.new("c1", :agility, 14)

    assert match?(%Check{id: _, trait: _, difficulty: _}, c)
    assert c.id == "c1"
    assert c.trait == :agility
    assert c.difficulty == 14
    assert c.advantage == false
    assert c.disadvantage == false
    assert c.status == :open
    assert c.rolls == %{}
  end

  test "new/4 applies opts" do
    c = Check.new("c1", :agility, 14, advantage: true, created_by: :dm)

    assert c.advantage == true
    assert c.disadvantage == false
    assert c.created_by == :dm
  end

  test "put_roll/3 stores result under player id" do
    c = Check.new("c1", :agility, 14)

    #fake result struct is fine (we're just testing storage)

    r = %Duality{
      hope_die: 1,
      fear_die: 2,
      total: 3,
      difficulty: 14,
      success?: false,
      critical?: false,
      category: :failure_with_fear,
      with: :fear,
      hope_delta: 0,
      fear_delta: 1,
      advantage_d6: nil,
      disadvantage_d6: nil,
      trait_mod: nil,
      extra_mod: nil,
      clear_stress?: false
    }

    c2 = Check.put_roll(c, "alice", r)

    assert c.rolls == %{}
    assert %{"alice" => %Duality{}} = c2.rolls
    assert c2.rolls["alice"].total == 3

  end

  test "put_roll/3 stores multiple players" do
    c = Check.new("c1", :agility, 14)

    r1 = %Duality{
      hope_die: 1, fear_die: 2, total: 3, difficulty: 14,
      success?: false, critical?: false, category:  :failure, with: :fear,
      hope_delta: 0, fear_delta: 1, advantage_d6: nil, disadvantage_d6: nil,
      trait_mod: nil, extra_mod: nil, clear_stress?: false
    }

    r2 = %Duality{r1 | hope_die: 12, fear_die: 12, total: 24,
      success?: true, critical?: true, category: :critical_success,
      fear_delta: 0, clear_stress?: true }

    c2 =
      c
      |> Check.put_roll("alice", r1)
      |> Check.put_roll("bob", r2)

    assert Map.has_key?(c2.rolls, "alice")
    assert Map.has_key?(c2.rolls, "bob")
    assert c2.rolls["bob"].critical? == true

    end

  test "put_roll/3 overwrites a player's roll " do
    c = Check.new("c1", :agility, 14)

    r1 = %Duality{
      hope_die: 1, fear_die: 2, total: 3, difficulty: 14,
      success?: false, critical?: false, category:  :failure, with: :fear,
      hope_delta: 0, fear_delta: 1, advantage_d6: nil, disadvantage_d6: nil,
      trait_mod: nil, extra_mod: nil, clear_stress?: false
    }

    r2 = %Duality{r1 | total: 20}

    c2 =
      c
      |> Check.put_roll("alice", r1)
      |> Check.put_roll("alice", r2)

    assert c2.rolls["alice"].total == 20

  end

  test "put_roll/3 rejects non-Duality results" do
    c = Check.new("c1", :agility, 14 )

    assert_raise FunctionClauseError, fn ->
      Check.put_roll(c, "alice", %{total: 3})
    end
  end

  test "put_roll/3 rejects rolls when check is closed" do
    c = Check.new("c1", :agility, 14) |> Check.close()

    r = %Duality{hope_die: 1, fear_die: 2, total: 3, difficulty: 14,
      success?: false, critical?: false, category:  :failure, with: :fear,
      hope_delta: 0, fear_delta: 1, advantage_d6: nil, disadvantage_d6: nil,
      trait_mod: nil, extra_mod: nil, clear_stress?: false}

    assert_raise FunctionClauseError, fn ->
      Check.put_roll(c, "alice", r)
    end
  end

  test "close/1 marks status closed" do
    c = Check.new("c1", :agility, 14)
    c2 = Check.close(c)

    assert c.status == :open
    assert c2.status == :closed
  end

  test "close/1 is idempotent (closing twice stays closed)" do
    c = Check.new("c1", :agility, 14)
    c2 = Check.close(c)
    c3 = Check.close(c2)

    assert c2.status == :closed
    assert c3.status == :closed
  end

  test "close/1 preserves rolls" do
    c = Check.new("c1", :agility, 14)

    r = %Duality{hope_die: 1, fear_die: 2, total: 3, difficulty: 14,
      success?: false, critical?: false, category:  :failure, with: :fear,
      hope_delta: 0, fear_delta: 1, advantage_d6: nil, disadvantage_d6: nil,
      trait_mod: nil, extra_mod: nil, clear_stress?: false}

    c2 = Check.put_roll(c, "alice", r)

    c3 = Check.close(c2)

    assert c3.rolls == c2.rolls
  end

  test "new/4 rejects non-positive difficulty" do
    assert_raise FunctionClauseError, fn ->
      Check.new("c1", :agility, 0)
    end
  end

end
