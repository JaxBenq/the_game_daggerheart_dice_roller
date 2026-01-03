defmodule Daggerheart.Duality do
  @moduledoc """
  Core Daggerheart duality dice logic (Hope/Fear d12 pair).

  This module is *pure*": it does no state or IO. It just:
    * rolls dice using 'DiceRoller'
    *applies Daggerheart-style rules
    *returns a structured result
  """

  @typedoc "Who the result is associated with"
  @type side :: :hope | :fear

  @typedoc "Outcome category of an action roll"
  @type category ::
          :critical_success
          | :success_with_hope
          | :success_with_fear
          | :failure_with_hope
          | :failure_with_fear
  @typedoc "Result of a single duality action roll"
  @type t :: %__MODULE__{
    total: integer(),
    success?: boolean(),
    critical?: boolean(),
    with: side(),
    category: category(),
    hope_die: pos_integer(),
    fear_die: pos_integer(),
    advantage_d6: integer() | nil,
    disadvantage_d6: integer() | nil,
    trait_mod: integer(),
    extra_mod: integer(),
    difficulty: pos_integer(),
    hope_delta: integer(),
    fear_delta: integer(),
    clear_stress?: boolean()
  }

  @enforce_keys [
    :total,
    :success?,
    :critical?,
    :with,
    :category,
    :hope_die,
    :fear_die,
    :advantage_d6,
    :disadvantage_d6,
    :trait_mod,
    :extra_mod,
    :difficulty,
    :hope_delta,
    :fear_delta,
    :clear_stress?
  ]
  defstruct @enforce_keys

  @type roller :: (pos_integer() -> pos_integer())

  @doc """
  Performs a Daggerheart-style action roll.

  Arguments:
    * 'trait_mod'    - the character's trait modifier (e.g. +1)
    * 'difficulty'   - target number to beat or meet
    * 'opts'         - keyword options:
      * ':extra_mod'    - flat extra modifier (default 0)
      * ':advantage'    - boolean, if true adds + 1d6
      * ':disadvantage' - boolean, if true subtracts 1d6

  Behaviour (simplified to match our spec):

    * Roll 2d12: Hope die (h) and Fear die (f)
    * Optionally roll +d6 (advantage) and/or -d6 (disadvantage)
    * total = h + f + trait_mod + extra_mod + adv_d6 - dis_d6
    * If h == f -> critical success:
        - success? = true
        - with = :hope
        - category = :critical_success
        - hope_delta = +1
        - fear_delta = 0
        - clear_stress? = true
    * Otherwise:
      - success? = total >= difficulty
      - If success? && h > f -> :success_with_hope, hope_delta +1
      - If success? && f > h -> :success_with_fear, fear_delta +1
      - If !success? && h > f -> :failure_with_hope, hope_delta +1
      - If !success? && f > h -> :failure_with_fear, fear_delta +1

  Returns a '%Daggerheart.Duality{}' struct
  """

  @spec roll_action(trait_mod :: integer(), difficulty :: pos_integer(), keyword()) :: t()
  def roll_action(trait_mod, difficulty, opts \\ [])
    when is_integer(trait_mod) and is_integer(difficulty) and difficulty > 0 do
    roll_action_with(trait_mod, difficulty, opts, &DiceRoller.roll/1)
    end



  @spec roll_action_with(trait_mod :: integer(), difficulty :: pos_integer(), keyword(), roller()) :: t()
  defp roll_action_with(trait_mod, difficulty, opts, roller)
    when is_function(roller, 1) do
      extra_mod = Keyword.get(opts, :extra_mod, 0)
      advantage? = Keyword.get(opts, :advantage, false)
      disadvantage? = Keyword.get(opts, :disadvantage, false)

      hope_die = roller.(12)
      fear_die = roller.(12)

      advantage_d6 =
        if advantage?, do: roller.(6), else: nil

      disadvantage_d6 =
        if disadvantage?, do: roller.(6), else: nil

      adv_value = advantage_d6 || 0
      dis_value = disadvantage_d6 || 0

      total = hope_die + fear_die + trait_mod + extra_mod + adv_value - dis_value

      base = %{
        hope_die: hope_die,
        fear_die: fear_die,
        advantage_d6: advantage_d6,
        disadvantage_d6: disadvantage_d6,
        trait_mod: trait_mod,
        extra_mod: extra_mod,
        difficulty: difficulty,
        total: total
      }

      if hope_die == fear_die do
        build_critical_result(base)
      else
        build_normal_result(base)
      end

    end

    ## === internal helpers ===

    defp build_critical_result(%{
      hope_die: hope_die,
      fear_die: fear_die,
      advantage_d6: adv,
      disadvantage_d6: dis,
      trait_mod: trait_mod,
      extra_mod: extra_mod,
      difficulty: difficulty,
      total: total
    }) do
      %__MODULE__{
        total: total,
        success?: true,
        critical?: true,
        with: :hope,
        category: :critical_success,
        hope_die: hope_die,
        fear_die: fear_die,
        advantage_d6: adv,
        disadvantage_d6: dis,
        trait_mod: trait_mod,
        extra_mod: extra_mod,
        difficulty: difficulty,
        hope_delta: 1,
        fear_delta: 0,
        clear_stress?: true
      }
    end

    defp build_normal_result(%{
      hope_die: hope_die,
      fear_die: fear_die,
      advantage_d6: adv,
      disadvantage_d6: dis,
      trait_mod: trait_mod,
      extra_mod: extra_mod,
      difficulty: difficulty,
      total: total
    }) do
      success? = total >= difficulty

      {with, category, hope_delta, fear_delta} =
        case {success?, hope_die > fear_die} do
          {true, true} ->
            {:hope, :success_with_hope, 1, 0}
          {true, false} ->
            {:fear, :success_with_fear, 0, 1}
          {false, true} ->
            {:hope, :failure_with_hope, 1, 0}
          {false, false} ->
            {:fear, :failure_with_fear, 0, 1}
        end

      %__MODULE__{
        total: total,
        success?: success?,
        critical?: false,
        with: with,
        category: category,
        hope_die: hope_die,
        fear_die: fear_die,
        advantage_d6: adv,
        disadvantage_d6: dis,
        trait_mod: trait_mod,
        extra_mod: extra_mod,
        difficulty: difficulty,
        hope_delta: hope_delta,
        fear_delta: fear_delta,
        clear_stress?: false
      }
    end

    if Mix.env() == :test do
      @doc false
      def roll_action_test(trait_mod, difficulty, opts, roller) do
        roll_action_with(trait_mod, difficulty, opts, roller)
      end
    end
end
