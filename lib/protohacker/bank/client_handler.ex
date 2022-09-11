defmodule Protohacker.Bank.ClientHandler do
  require Logger

  def start(client_socket) do
    asset_table = :ets.new(:asset_data, [:set])
    serve(client_socket, asset_table)
  end

  @message_size 9
  def serve(client_socket, asset_table) do
    case :gen_tcp.recv(client_socket, @message_size) do
      {:ok, message} ->
        process_message(message, asset_table)
        |> reply(client_socket)

        serve(client_socket, asset_table)

      error ->
        Logger.debug("Closing (#{inspect(client_socket)}): #{inspect(error)}")
        :gen_tcp.close(client_socket)
    end
  end

  defp process_message(
         <<
           "I",
           timestamp::signed-integer-size(32),
           price::signed-integer-size(32)
         >>,
         table
       ) do
    :ets.insert(table, {timestamp, price})

    {:insert, :ok}
  end

  defp process_message(
         <<
           "Q",
           min_time::signed-integer-size(32),
           max_time::signed-integer-size(32)
         >>,
         table
       ) do
    mean =
      :ets.select(table, build_matchspec(min_time, max_time))
      |> case do
        [] -> 0
        prices -> Enum.sum(prices) / length(prices)
      end
      |> floor()
      |> pack()

    {:query, mean}
  end

  defp process_message(message, _table), do: {:error, message}

  defp build_matchspec(min, max) do
    [{{:"$1", :"$2"}, [{:andalso, {:>=, :"$1", min}, {:"=<", :"$1", max}}], [:"$2"]}]
  end

  defp pack(int32), do: <<int32::signed-integer-size(32)>>

  defp reply({:query, mean}, client_socket), do: :gen_tcp.send(client_socket, mean)
  defp reply(_, _), do: nil
end
