ExUnit.start()
{:ok, _} = Registry.start_link(keys: :unique, name: Daggerheart.TestRegistry)
