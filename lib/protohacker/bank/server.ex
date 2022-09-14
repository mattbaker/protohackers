defmodule Protohacker.Bank.Server do
  require Logger
  import Protohacker.BinaryShorthand

  def start(socket, _opts) do
    asset_table = :ets.new(:asset_data, [:set])
    serve(socket, asset_table)
  end

  @message_size 9
  defp serve(socket, asset_table) do
    case :gen_tcp.recv(socket, @message_size) do
      {:ok, message} ->
        process_message(message, asset_table)
        |> reply(socket)

        serve(socket, asset_table)

      _error ->
        Logger.debug("#{inspect(__MODULE__)}: Client Closed (#{inspect(socket)})")
        :gen_tcp.close(socket)
    end
  end

  defp process_message(<<"I", timestamp::int32(), price::int32()>>, table) do
    :ets.insert(table, {timestamp, price})

    {:insert, :ok}
  end

  defp process_message(<<"Q", min_time::int32(), max_time::int32()>>, table) do
    mean =
      :ets.select(table, build_matchspec(min_time, max_time))
      |> mean()
      |> floor()
      |> pack()

    {:query, mean}
  end

  defp process_message(message, _table), do: {:error, message}

  # Generated with :ets.fun2ms/1
  defp build_matchspec(min, max) do
    [{{:"$1", :"$2"}, [{:andalso, {:>=, :"$1", min}, {:"=<", :"$1", max}}], [:"$2"]}]
  end

  defp mean([]), do: 0
  defp mean(prices), do: Enum.sum(prices) / length(prices)

  defp pack(int32), do: <<int32::int32()>>

  defp reply({:query, mean}, socket), do: :gen_tcp.send(socket, mean)
  defp reply(_, _), do: nil
end
