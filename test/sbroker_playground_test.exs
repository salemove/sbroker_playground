defmodule SbrokerPlaygroundTest do
  use ExUnit.Case
  doctest SbrokerPlayground

  test "greets the world" do
    assert SbrokerPlayground.hello() == :world
  end
end
