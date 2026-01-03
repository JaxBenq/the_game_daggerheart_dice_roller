defmodule Daggerheart.TableTest do
  use ExUnit.Case, async: true

  alias Daggerheart.{Table, Player, Check, Duality}

  defp duality(overrides \\ %{}) do
    base = %Duality{
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

    struct!(Duality, Map.merge(Map.from_struct(base), overrides))
  end


  test "new/1 uses default history_limit 50" do
    t = Table.new()

    assert match?(%Table{history_limit: _}, t)
    assert t.history_limit == 50
    assert t.players == %{}
    assert t.players == %{}
    assert t.history == []
    assert t.hope_pool == 0
    assert t.fear_pool == 0
  end

  test "new/1 accepts history_limit option" do
    historyLimit = [{:history_limit,60}]
    t = Table.new(historyLimit)

    assert t.history_limit == 60
  end

  test "put_player/2 inserts and overwrites by id" do
    t = Table.new()

    p1 = Player.new("alice", "Alice", %{agility: 2})
    t2 = Table.put_player(t, p1)

    assert Map.has_key?(t2.players, "alice")
    assert t2.players["alice"].name == "Alice"

    p2 = Player.new("alice", "Alice v2", %{agility: 3})
    t3 = Table.put_player(t2, p2)

    assert t3.players["alice"].name == "Alice v2"
    assert Player.trait_mod(t3.players["alice"], :agility) == 3
  end

  test "put_check/2 inserts and overwrites by id" do
    t = Table.new()

    c1 = Check.new("c1", :agility, 10)
    t2 = Table.put_check(t, c1)

    assert Map.has_key?(t2.checks, "c1")
    assert t2.checks["c1"].difficulty == 10

    c2 = Check.new("c1", :agility, 12)
    t3 = Table.put_check(t2, c2)

    assert t3.checks["c1"].difficulty == 12

  end

  test "apply_result/2 updates pools and prepends to history" do
    t = Table.new(history_limit: 10)
    r = duality(%{hope_delta: 2, fear_delta: 1 })

    t2 = Table.apply_result(t, r)

    assert t2.hope_pool == 2
    assert t2.fear_pool == 1
    assert length(t2.history) == 1
    assert hd(t2.history) == r

  end

  test "apply_result/2 clamps pools at 0 (never negative)" do
    t =
      Table.new(history_limit: 10)
      |> Map.put(:hope_pool, 0)
      |> Map.put(:fear_pool, 0)

    r = duality(%{hope_delta: -5, fear_delta: -3})

    t2 = Table.apply_result(t, r)

    assert t2.hope_pool == 0
    assert t2.fear_pool == 0

  end

  test "apply_result/2 enforces history_limit" do
    t = Table.new(history_limit: 2)

    r1 = duality(%{total: 1})
    r2 = duality(%{total: 2})
    r3 = duality(%{total: 3})

    t2 = Table.apply_result(t, r1)
    t3 = Table.apply_result(t2, r2)
    t4 = Table.apply_result(t3, r3)

    assert length(t4.history) == 2
    assert Enum.map(t4.history, & &1.total) == [3,2]
  end

  test "record_player_roll/4 updates check rolls AND applies result to pools/history" do
    t =
      Table.new(history_limit: 10)
      |> Table.put_player(Player.new("alice", "Alice", %{agility: 2}))
      |> Table.put_check(Check.new("c1", :agility, 14))

    r = duality(%{hope_delta: 1, fear_delta: 0, total: 20})

    {t2, updated_check} = Table.record_player_roll(t, "c1", "alice", r)


    # check returned updated
    assert match?(%Check{id: "c1"}, updated_check)
    assert updated_check.rolls["alice"].total == 20

    #table updated
    assert t2.hope_pool == 1
    assert t2.fear_pool == 0
    assert length(t2.history) == 1
    assert hd(t2.history).total == 20

    #check stored back into table
    assert t2.checks["c1"].rolls["alice"].total == 20
  end

  test " record_player_roll/4 returns {table, :error} if check is missing" do
    t = Table.new()
    r = duality()

    {t2, res} = Table.record_player_roll(t, "missing", "alice", r)

    assert t2 == t
    assert res == :error
  end

  test "record_player_roll/4 raises if check exists but is closed (since Check.put_roll requires open)" do
    t =
      Table.new()
      |> Table.put_check(Check.new("c1", :agility, 14) |> Check.close())

    r = duality()


    assert_raise FunctionClauseError, fn ->
      Table.record_player_roll(t, "c1", "alice", r)

    end

  end

end
