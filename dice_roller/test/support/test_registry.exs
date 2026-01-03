defmodule Daggerheart.TestRegistry do
  def child_spec(_args) do
    Registry.child_spec(keys: :unique, name: __MODULE__)
  end
end
