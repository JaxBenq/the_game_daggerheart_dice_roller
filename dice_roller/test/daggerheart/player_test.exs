defmodule Daggerheart.PlayerTest do
  use ExUnit.Case, async: true

  alias Daggerheart.Player

  test "new/3 builds a player with default traits" do
    p = Player.new("alice", "Alice")

    assert %Player{} = p
    assert p.id == "alice"
    assert p.name == "Alice"
    assert p.traits == %{}
  end

  test "new/3 stores provided traits as-is" do
    traits = %{agility: 2, might: -1, presence: 0}
    p = PLayer.new("alice", "Alice", traits)

    assert p.traits == traits

  end

  test "trait_mod/2 returns modifier or 0 if missing" do
    p = Player.new("alice", "Alice",  %{agility: 2, might: 1})

    assert Player.trait_mod(p, :agility) == 2
    assert Player.trait_mod(p, :might) == 1
    assert Player.trait_mod(p, :presence) == 0
  end

end
