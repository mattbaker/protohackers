defmodule Protohacker.Prime.Server do
  require Logger

  def start(socket, _opts), do: serve(socket)

  defp serve(socket) do
    with {:ok, json} <- :gen_tcp.recv(socket, 0),
         {:ok, data} <- Jason.decode(json),
         {:ok, response} <- build_response(data),
         {:ok, encoded_response} <- Jason.encode(response),
         :ok <- send_response(encoded_response, socket) do
      serve(socket)
    else
      _error ->
        Logger.debug("#{inspect(__MODULE__)}: Client Closed (#{inspect(socket)})")
        :gen_tcp.close(socket)
    end
  end

  defp build_response(%{"method" => "isPrime", "number" => number}) when is_number(number) do
    {:ok, %{"method" => "isPrime", "prime" => is_prime?(number)}}
  end

  defp build_response(_), do: {:error, :invalid_object}

  defp is_prime?(n) do
    cond do
      is_float(n) -> false
      n < 0 -> false
      n == 0 -> false
      n == 1 -> false
      n == 2 -> true
      n == 3 -> true
      rem(n, 2) == 0 -> false
      rem(n, 3) == 0 -> false
      true -> has_factors?(n)
    end
  end

  defp has_factors?(n) do
    limit = :math.sqrt(n) |> floor()

    Stream.drop_while(5..limit//6, fn i ->
      rem(n, i) != 0 && rem(n, i + 2) != 0
    end)
    |> Enum.empty?()
  end

  defp send_response(data, socket), do: :gen_tcp.send(socket, data <> "\n")
end
