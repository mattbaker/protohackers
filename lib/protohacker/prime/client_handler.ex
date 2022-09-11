defmodule Protohacker.Prime.ClientHandler do
  require Logger

  def start(client_socket) do
    serve(client_socket)
  end

  defp serve(client_socket) do
    with {:ok, json} <- :gen_tcp.recv(client_socket, 0),
         {:ok, data} <- Jason.decode(json),
         {:ok, response} <- build_response(data),
         {:ok, encoded_response} <- Jason.encode(response),
         :ok <- send_response(encoded_response, client_socket) do
      serve(client_socket)
    else
      error ->
        Logger.info("Closing (#{inspect(client_socket)}): #{inspect(error)}")
        :gen_tcp.close(client_socket)
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

    5..limit//6
    |> Stream.drop_while(fn i ->
      rem(n, i) != 0 && rem(n, i + 2) != 0
    end)
    |> Enum.empty?()
  end

  defp send_response(data, socket), do: :gen_tcp.send(socket, data <> "\n")
end
