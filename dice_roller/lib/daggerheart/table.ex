defmodule Daggerheart.Table do
  @moduledoc """
  Pure representation of a Daggerheart table state.

  Holds:
    * players
    * hope/fear pools
    * checks
    * history of action results
  """

  alias Daggerheart.{Player, Check, Duality}

  @typedoc "Map of player_id => Player"
  @type players_map :: %{optional(Player.id()) => Player.t()}

  @typedoc "Map of check_id => Check"
  @type check_map :: %{optional(Check.id()) => Check.t()}

  @typedoc "History entry - for now, we just store the Duality result."
  @type history_entry :: Duality.t()

  @typedoc "Table state"
  @type t :: %__MODULE__{
    players: players_map(),
    hope_pool: non_neg_integer(),
    fear_pool: non_neg_integer(),
    checks: check_map(),
    history: [history_entry()],
    history_limit: pos_integer()
  }

  @enforce_keys [:history_limit]
  defstruct  players: %{},
             hope_pool: 0,
             fear_pool: 0,
             checks: %{},
             history: [],
             history_limit: 50

  @doc """
  Creates a new, empty table state.

  'opts':
    * ':history_limit' - max number of history entries to keep (default 50)
  """
  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    limit = Keyword.get(opts, :history_limit, 50)

    %__MODULE__{
      history_limit: limit
    }
  end

  @doc """
  Registers or updates a player in the table.

  If the player id already exists, it overwrites that entry.
  """

  @spec put_player(t(), Player.t()) :: t()
  def put_player(%__MODULE__{players: players} = table, %Player{id: id} = player) do
    %{table | players: Map.put(players, id, player)}
  end

  @doc """
  Inserts a new check into the table.

  The 'check' must already have an id.
  """
  @spec put_check(t(),  Check.t()) :: t()
  def put_check(%__MODULE__{checks: checks} = table, %Check{id: id} = check) do
    %{table | checks: Map.put(checks, id, check)}
  end

  @doc """
  Applies a Duality result to the table:

    * updates hope/fear pools according to hope_delta/fear_delta
    * adds the result to history (bounded by history_limit)
  """
  @spec apply_result(t(), Duality.t()) :: t()
  def apply_result(%__MODULE__{
    hope_pool: hope,
    fear_pool: fear,
    history: history,
    history_limit: limit} = table,
    %Duality{hope_delta: h_delta, fear_delta: f_delta} = result) do
      new_hope = max(0, hope + h_delta)
      new_fear = max(0, fear + f_delta)

      new_history =
        [result | history]
        |> Enum.take(limit)

      %{
        table
        | hope_pool: new_hope,
          fear_pool: new_fear,
          history: new_history}
    end

    @doc """
    Attaches a player's roll result to a given check *and* applies the results to pools/history.

    Returns '{new_table, updated_check}'.

    If the check id doesn't exist, it returns the table unchanged and ':error'.
    """

    @spec record_player_roll(t(), Check.id(), Player.id(), Duality.t()) :: {t(), Check.t() | :error}
    def record_player_roll(%__MODULE__{checks: checks} = table, check_id, player_id, result) do
      case Map.fetch(checks, check_id) do
        {:ok, check} ->
          updated_check = Check.put_roll(check, player_id, result)

          new_table =
            table
            |> apply_result(result)
            |> put_check(updated_check)

            {new_table, updated_check}
        :error ->
          {table, :error}
      end
    end
end
