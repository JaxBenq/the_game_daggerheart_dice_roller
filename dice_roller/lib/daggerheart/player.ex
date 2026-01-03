defmodule Daggerheart.Player do
  @moduledoc """
  Represents a Daggerheart player at the table: id, name, and traits.

  Traits are a map of 'trait_name => modifier', for example:

    %{
      agility: 2,
      might:1,
      presence: 0
      }
  """

  @typedoc "Player identifier - can be an integer, UUID, etc."
  @type id :: term()

  @typedoc "Trait name - usually :agility, :might, :presence, etc."
  @type trait_name :: atom()

  @typedoc "Trait modifiers map"
  @type traits_map :: %{optional(trait_name()) => integer()}

  @typedoc "Trait modifier map"
  @type t :: %__MODULE__{
    id: id(),
    name: String.t(),
    traits: traits_map()
  }

  @enforce_keys [:id, :name]
  defstruct id: nil,
            name: "",
            traits: %{}

  @doc """
  Creates a new player profile.

  'id' can be any term (string, integer, etc.).
  'traits' is a map of 'trait_name => modifier'.
  """

  @spec new(id(), String.t(), traits_map()) :: t()
  def new(id, name, traits \\ %{}) when is_binary(name) do
    %__MODULE__{
      id: id,
      name: name,
      traits: traits
    }
  end

  @doc """
  Gets the modifier for a given trait, or 0 if it's not defined.
  """
  @spec trait_mod(t(), trait_name()) :: integer()
  def trait_mod(%__MODULE__{traits: traits}, trait) do
    Map.get(traits, trait, 0)
  end
end
