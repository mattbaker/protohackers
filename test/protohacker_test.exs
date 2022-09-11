defmodule ProtohackerTest do
  use ExUnit.Case
  doctest Protohacker

  test "greets the world" do
    assert Protohacker.hello() == :world
  end
end
