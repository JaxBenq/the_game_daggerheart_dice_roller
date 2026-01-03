defmodule DiceRoller.Server do
  @moduledoc """
  GenServer wrapper around DiceRoller that keeps roll statisticis

  State shape:
    %{
      total_rolls: non_neg_integer(),
      criticals: non_neg_integer(),
      last_roll: nil | %{sides: pos_integer(), value: pos_integer(), flag :normal | :critical}
  """

  use GenServer

  ## === Client API ===

    @doc """
    Starts the DiceRoller server.

    Options:
      * ':name' -register the process under a local name.
    ## Examples

      iex> {:ok, pid} = DiceRoller.Server.start_link()
      iex> is_pid(pid)
      true

    """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @doc """
  Rolls a die with 'sides' side through the server.

  Returns '{:ok, value, flag} where 'flag' is ':normal' or ':critical'.
  """

  def roll(server \\ __MODULE__, sides) do
    GenServer.call(server, {:roll, sides})
  end

  @doc """
  Reutrns the current statistics.

  Example shape:
    %{
      total_rolls:10,
      criticals:2,
      last_roll: %{sides:20, value: 20, flag: critical}
      }
  """

  def stats(server \\ __MODULE__) do
    GenServer.call(server, :stats)
  end

  @doc """
  Resets the statistics back to initial values.
  """

  def reset(server \\ __MODULE__) do
    GenServer.call(server, :reset)
  end

  @doc """
  Perfomrs a check using 'DiceRoller.roll_check/1'

  Returns '{:success, value}' or '{:fail, value}' and updates stats.
  """

  def roll_check(server \\ __MODULE__, sides) do
    GenServer.call(server, {:roll_check, sides})
  end

  @doc """
  Rolls with advantage through the server.

  Returns '{:ok, best, {r1. r2}, flag}'.
  """

  def roll_adv(server \\ __MODULE__, sides) do
    GenServer.call(server, {:roll_adv, sides})
  end

  @doc """
  Rolls with disadvantage through the server.

  Returns '{:ok, worst, {r1, r2}, flag}'.
  """

  def roll_dis(server \\ __MODULE__, sides) do
    GenServer.call(server, {:roll_dis, sides})
  end

  @doc """
  Returns the last N roll entries (history), newest first
  """

  def history(server \\ __MODULE__) do
    GenServer.call(server, :history)
  end

  @doc """
  Rolls with crit confirmation through the server.

  Uses 'DiceRoller.roll_with_confirm/1'.

  Returns:
    * '{:normal, value}
    * '{:critical, value, confirm}
  """

  def roll_with_confirm(server \\ __MODULE__, sides) do
    GenServer.call(server, {:roll_with_confirm, sides})
  end

  ## === Server (GenServer callbacks) ===
    @history_limit 20

    @impl true
    def init(:ok) do
      state = %{
        total_rolls: 0,
        criticals: 0,
        last_roll: nil,
        successes: 0,
        failures: 0,
        history: [] # newest first
      }

      {:ok, state}
    end

    @impl true
    def handle_call({:roll, sides}, _from, state) when is_integer(sides) and sides > 0 do
      {flag, value} = DiceRoller.roll_with_flags(sides)

      new_state =
        state
        |> increment_total()
        |> maybe_increment_crit(flag)
        |> put_last_roll(sides, value, flag)

      {:reply, {:ok, value, flag}, new_state}
    end

    def handle_call({:roll, _sides}, _from, state) do
      {:reply, {:error, :invalid_sides}, state}
    end

    @impl true
    def handle_call(:stats, _from, state) do
      {:reply, state, state}
    end

    @impl true
    def handle_call({:roll_check, sides}, _from, state) when is_integer(sides) and sides > 0 do
      result = DiceRoller.roll_check(sides)

      new_state=
        case result do
          {:success, _value} ->
            state
            |> increment_total()
            |> increment_success()

          {:fail, _value} ->
            state
            |> increment_total()
            |> increment_failure()
        end
        {:reply, result, new_state}
    end

    def handle_call({:roll_check, _bad_sides}, _from, state) do
      {:reply, {:error, :invalid_sides}, state}
    end

    @impl true
    def handle_call({:roll_adv, sides}, _from, state) when is_integer(sides) and sides > 0 do
      {value, {r1, r2}} = DiceRoller.roll_adv(sides)
      flag = if value == sides, do: :critical, else: :normal

      new_state =
        state
        |> increment_total()
        |> maybe_increment_crit(flag)
        |> put_last_roll(sides, value, flag, :advantage)

        {:reply, {:ok, value, {r1,r2}, flag}, new_state}
    end

    def handle_call({:roll_adv, _bad_sides}, _from, state) do
      {:reply, {:error, :invalid_sides}, state}
    end
    @impl true
    def handle_call({:roll_dis, sides}, _from, state) when is_integer(sides) and sides > 0 do
      {value, {r1, r2}} = DiceRoller.roll_dis(sides)
      flag = if value == sides, do: :critical, else: :normal

      new_state =
        state
        |> increment_total()
        |> maybe_increment_crit(flag)
        |> put_last_roll(sides, value, flag, :disadvantage)

        {:reply, {:ok, {r1,r2}, flag}, new_state}
    end

    def handle_call({:roll_dis, _bad_sides}, _from, state) do
      {:reply, {:error, :invalid_sides}, state}
    end

    @impl true
    def handle_call(:history, _from, state) do
      {:reply, state.history, state}
    end

    @impl true
    def handle_call({:roll_with_confirm, sides}, _from, state) when is_integer(sides) and sides > 0 do
    result = DiceRoller.roll_with_confirm(sides)

    {flag, value} =
      case result do
        {:normal, v} -> {:normal, v}
        {:critical, v, _confirm} -> {:critical, v}
      end
    new_state =
      state
      |> increment_total()
      |> maybe_increment_crit(flag)
      |> put_last_roll(sides, value, flag, :confirm)

      {:reply, result, new_state}
    end

    def handle_call({:roll_with_confirm, _}, _from, state) do
      {:reply, {:error, :invalid_sides}, state}
    end

    @impl true
    def handle_cast(:reset, _state) do
      new_state = %{
        total_rolls: 0,
        criticals: 0,
        last_roll: nil,
        successes: 0,
        failures: 0,
        history: []
      }

      {:noreply, new_state}
    end

    ## === Internal helpers ===
      defp increment_total(state) do
        Map.update!(state, :total_rolls, &(&1+1))
      end

      defp maybe_increment_crit(state, :critical) do
        Map.update!(state, :criticals, &(&1+1))
      end

      defp maybe_increment_crit(state, _flag), do: state

      defp put_last_roll(state, sides, value, flag, kind \\ :normal) do
        entry = %{
          kind: kind,  # :normal | :advantage | :disadvantage |: check | ...
          sides: sides,
          value: value,
          flag: flag # :normal | :critical | nil
        }

        state
        |> Map.put(:last_roll, entry)
        |> add_to_history(entry)
      end

      defp increment_success(state) do
        Map.update!(state, :successes, &(&1+1))
      end

      defp increment_failure(state) do
        Map.update!(state, :failures, &(&1+1))
      end

      defp add_to_history(state, entry) do
        history =
          [entry | state.history]
          |> Enum.take(@history_limit)

        %{state | history: history}
      end

end
