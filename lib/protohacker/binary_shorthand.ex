defmodule Protohacker.BinaryShorthand do
  @moduledoc """
  Shorthand for common binary pattern specifiers
  """
  defmacro int32 do
    quote do
      signed - integer - size(32)
    end
  end

  defmacro uint32 do
    quote do
      unsigned - integer - size(32)
    end
  end

  defmacro uint8 do
    quote do
      unsigned - integer - size(8)
    end
  end
end
