defmodule Daggerheart.TableServer do
  @moduledoc """
  GenServer wrapper around "Daggeheart.Table".

  Responsibilities:
    * hold a single table"s state in memory
    * register / update players
    * roll for players (using Duality)
    * expose pools, checks, and history
  """

  use GenServer

  alias Daggerheart.{Table, Player, Check, Duality}

  ## === Client API ===

    @doc """
    Starts a table server.

    Options:
      * ":name"          - registered name(default: ;Daggerheart.TableServer")
      * ":history_limit" - max history entries (passed to ;Table.new/1")
    """

    def start_link(opts \\ []) do
      name = Keyword.get(opts, :name, __MODULE__)

      GenServer.start_link(__MODULE__, opts, name: name)
    end

    @doc """
    Registers or updates a player on this table.

    "id" can be any term (string, atom ,integer).
    "traits" is a map of "trait_name+> modifier".

    Returns "{:ok, player}".
    """
    def register_player(id, name, traits \\ %{}) do
      GenServer.call(__MODULE__, {:register_player, id, name, traits})
    end

    def register_player(server, id, name, traits) do
      GenServer.call(server, {:register_player, id, name, traits})
    end

    @doc """
    Starts a new check on this table.

    "check_id" is provided by the caller (can be a string, atom, etc.).
    "trait" is the trait to use (e.g. :agility).
    "difficulty" is a positive integer.

    "opts" :
      * ":advantage"     - base advantage for everyone (default false)
      * ":disadvantage"  - base disadvantage (default false)
      * ":created_by"    - :dm or player id

    Returns "{ok, check}".
    """
    def start_check(check_id, trait, difficulty, opts \\ []) do
      GenServer.call(__MODULE__, {:start_check, check_id, trait, difficulty, opts})
    end

    def start_check(server, check_id, trait, difficulty, opts) do
      GenServer.call(server, {:start_check, check_id, trait, difficulty, opts})
    end

    @doc """
    Performs a Duality roll for a given player on a specific check.

    "roll_opts":
      * ":extra_mod"     - extra modifier (default 0)
      * ":advantage"     - override/add advantage flag
      * ":disadvantage"  - override/add disadvantage flag

    Advantage/disadvantage for the roll are computed as:

      base_adv = check.advantage
      base_dis = check.disadvantage
      roll_adv = roll_opts[:advantage] || base_adv
      roll_dis = roll_opts[:disadvantage] || base_dis

    Returns:application

      * "{:ok, result, updated_check}" on success
      * "{:error, :unknown_player}" if player id not found
      * "{:error, :unknown_check}" if check id is not found
    """
    def roll_for_player(check_id, player_id, roll_opts \\ []) do
      GenServer.call(__MODULE__, {:roll_for_player, check_id, player_id, roll_opts})
    end

    def roll_for_player(server, check_id, player_id, roll_opts) do
      GenServer.call(server, {:roll_for_player, check_id, player_id, roll_opts})
    end

    @doc """
    Returns the full table state struct.
    """
    def get_table() do
      GenServer.call(__MODULE__, :get_table)
    end
    def get_table(server) do
      GenServer.call(server, :get_table)
    end
    @doc """
    Returns "{hope_pool, fear_pool}".
    """
    def get_pools() do
      GenServer.call(__MODULE__, :get_pools)
    end
    def get_pools(server) do
      GenServer.call(server, :get_pools)
    end

    @doc """
    Returns "{:ok, check} pr ":error" if not found
    """

    def get_check(check_id) do
      GenServer.call(__MODULE__, {:get_check, check_id})
    end

    def get_check(server, check_id) do
      GenServer.call(server, {:get_check, check_id})
    end

    @doc """
    Returns the table"s history (list of %Daggerheart.Duality{}"), newest first.
    """

    def get_history() do
      GenServer.call(__MODULE__, :get_history)
    end
    def get_history(server) do
      GenServer.call(server, :get_history)
    end

  ## === Server (GenServer callbacks) ===

    @impl true
    def init(opts) do
      # opts is the same keyword list passed to start_link/1
      table = Table.new(opts)
      {:ok, table}
    end

    @impl true
    def handle_call({:register_player, id, name, traits}, _from, table) do
      player = Player.new(id, name, traits)
      new_table = Table.put_player(table, player)
      {:reply, {:ok, player}, new_table}
    end

    @impl true
    def handle_call({:start_check, check_id, trait, difficulty, opts}, _from, table) do
      check = Check.new(check_id, trait, difficulty, opts)
      new_table = Table.put_check(table, check)
      {:reply, {:ok, check}, new_table}
    end

    @impl true
    def handle_call({:roll_for_player, check_id, player_id, roll_opts}, _from, table) do
      with {:player, {:ok, player}} <- {:player, fetch_player(table, player_id)},
           {:check, {:ok, check}} <- {:check, fetch_check(table, check_id)} do
             trait_mod = Player.trait_mod(player, check.trait)

             extra_mod = Keyword.get(roll_opts, :extra_mod, 0)

             # Base advantage/disadvantage from the check
             base_adv = check.advantage
             base_dis = check.disadvantage

             # Roll-specific overrides (if any)
             roll_adv = Keyword.get(roll_opts, :advantage, base_adv)
             roll_dis = Keyword.get(roll_opts, :disadvantage, base_dis)

             result =
              Duality.roll_action(trait_mod, check.difficulty, extra_mod: extra_mod, advantage: roll_adv, disadvantage: roll_dis)

              {new_table, updated_check} =
                Table.record_player_roll(table, check_id, player_id, result)

              case updated_check do
                %Check{} = ch ->
                  {:reply, {:ok, result, ch}, new_table}

                :error ->
                  # Shouldn"t usually happen if fetch_check succeeded, but we handle it gracefully.
                  {:reply, {:error, :unknown_check}, table}
              end
      else
        {:player, :error} ->
          {:reply, {:error, :unknown_player}, table}
        {:check, :error} ->
          {:reply, {:error, :unknown_check}, table}
      end
    end

    @impl true
    def handle_call(:get_table, _from, table) do
      {:reply, table, table}
    end

    @impl true
    def handle_call(:get_pools, _from, table) do
      {:reply, {table.hope_pool, table.fear_pool}, table}
    end

    @impl true
    def handle_call({:get_check, check_id}, _from, table) do
      reply =
        case fetch_check(table, check_id) do
          {:ok, check} -> {:ok, check}
          :error -> :error
        end

        {:reply, reply, table}
    end

    @impl true
    def handle_call(:get_history, _from, table) do
      {:reply, table.history, table}
    end

  ## === Internal helpers ===

    defp fetch_player(%Table{players: players}, player_id) do
      Map.fetch(players, player_id)
    end

    defp fetch_check(%Table{checks: checks}, check_id) do
      Map.fetch(checks, check_id)
    end

end
