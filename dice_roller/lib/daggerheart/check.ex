defmodule Daggerheart.Check do
  @moduledoc """
  Represents a single Daggerheart check created by the DM.

  A check has:
    * an id
    * the trait to use (e.g. :agility)
    * the difficulty number
    * optional base advantage/disadvantage
    * a map of player rolls (player_id => %Daggerheart.Duality{})
  """

  alias Daggerheart.Duality
  alias Daggerheart.Player

  @typedoc "Check identifier"
  @type id :: term()

  @typedoc "Status of the check"
  @type status :: :open | :closed

  @typedoc "Map of player_id => duality result"
  @type rolls_map :: %{optional(Player.id()) => Duality.t}

  @typedoc "One check definition"
  @type t :: %__MODULE__{
    id: id(),
    trait: Player.trait_name(),
    difficulty: pos_integer(),
    advantage: boolean(),
    disadvantage: boolean(),
    created_by: :dm | Player.id() | nil,
    status: status(),
    rolls: rolls_map()
  }

  @enforce_keys [:id, :trait, :difficulty]
  defstruct id: nil,
            trait: nil,
            difficulty: 10,
            advantage: false,
            disadvantage: false,
            created_by: :dm,
            status: :open,
            rolls: %{}

  @doc """
  Creates a new open check.

  'id' is provided by the caller (later the TableServer can generate it)
  """
  @spec new(id(), Player.trait_name(), pos_integer(), keyword()) :: t()
  def new(id, trait, difficulty, opts \\ [])
  when is_integer(difficulty) and difficulty > 0 and is_atom(trait) do
    advantage = Keyword.get(opts, :advantage, false)
    disadvantage = Keyword.get(opts, :disadvantage, false)
    created_by = Keyword.get(opts, :created_by, :dm)

    %__MODULE__{
      id: id,
      trait: trait,
      difficulty: difficulty,
      advantage: advantage,
      disadvantage: disadvantage,
      created_by: created_by,
      status: :open,
      rolls: %{}
    }
  end

  @doc """
  Records a player's roll result in the check.

  Does not compute the roll - you pass in the '%Daggerheart.Duality{}' result.
  Returns an updated check.
  """

  @spec put_roll(t(), Player.id(), Duality.t()) :: t()
  def put_roll(%__MODULE__{status: :open, rolls: rolls} = check, player_id, %Duality{} = result) do
    %{check | rolls: Map.put(rolls, player_id, result)}
  end

  @doc """
  Marks the check as closed (no more rolls).
  """
  @spec close(t()) :: t()
  def close(%__MODULE__{} = check) do
    %{check | status: :closed}
  end
end
