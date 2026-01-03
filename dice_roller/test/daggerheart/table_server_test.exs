defmodule Daggerheart.TableServerTest do
  use ExUnit.Case, async: true

  alias Daggerheart.TableServer

  setup do
    # Make randomness reproducible for this test process
    :rand.seed(:exsplus, {101, 102, 103})

    # Unique server name per test (avoids collision when async)
    name = {:via, Registry, {Daggerheart.TestRegistry, make_ref()}}

    {:ok, _pid} = TableServer.start_link(name: name, history_limit: 50)

    %{server: name}
  end

  test "register players, start check, roll updates check and history", %{server: server} do
    {:ok, _alice} = TableServer.register_player(server, "alice", "Alice", %{agility: 2, might: 1})
    {:ok, _bob} = TableServer.register_player(server, "bob", "Bob", %{agility: 1})

    {:ok, _check} = TableServer.start_check(server, "check-1", :agility, 14, advantage: true)

    {:ok, res_a, check_after_a} = TableServer.roll_for_player(server, "check-1", "alice", [])
    assert %Daggerheart.Duality{} = res_a
    assert Map.has_key?(check_after_a.rolls, "alice")

    {:ok, _res_b, check_after_b} = TableServer.roll_for_player(server, "check-1", "bob", [disadvantage: true])

    assert Map.has_key?(check_after_b.rolls, "bob")

    history = TableServer.get_history(server)
    assert length(history) >= 2

    {hope, fear} = TableServer.get_pools(server)

    assert is_integer(hope) and hope >= 0
    assert is_integer(fear) and fear >= 0

    {:ok, check1} = TableServer.get_check(server, "check-1")

    assert Map.has_key?(check1.rolls, "alice")
    assert Map.has_key?(check1.rolls, "bob")

  end

  test "roll_for_player returns error for unknown ids", %{server: server} do
    assert {:error, :unknown_player} = TableServer.roll_for_player(server, "missing", "alice", [])

    {:ok, _check} = TableServer.start_check(server, "check-1", :agility, 10, [])
    assert {:error, :unknown_player} = TableServer.roll_for_player(server, "check-1", "missing", [])

    {:ok, _alice} = TableServer.register_player(server, "alice", "Alice", %{agility: 2})
    assert {:error, :unknown_check} = TableServer.roll_for_player(server, "missing", "alice", [])
  end
end
