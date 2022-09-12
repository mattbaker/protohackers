defmodule Protohacker.BinaryShorthand do
  defmacro int32 do
    quote do
      signed - integer - size(32)
    end
  end
end
