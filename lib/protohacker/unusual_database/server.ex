defmodule Protohacker.UnusualDatabase.Server do
  use GenServer

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts)

  def init(opts) do
    port = Keyword.fetch!(opts, :port)
    :gen_udp.open(port, [:binary, active: true])
    {:ok, %{}}
  end

  def handle_info({:udp, sock, host, port, data}, db) do
    parse(data)
    |> case do
      {:retrieve, key} ->
        :gen_udp.send(sock, host, port, retrieve(db, key))
        {:noreply, db}

      {:insert, key, value} ->
        {:noreply, insert(db, key, value)}

      {:error, _unknown} ->
        {:noreply, db}
    end
  end

  def handle_info(_, db), do: {:noreply, db}

  defp parse(message) when byte_size(message) < 1000 do
    Regex.run(~r/^([^=]*)=?(.*)/s, message)
    |> case do
      ["=", key, value] -> {:insert, key, value}
      [_, key, ""] -> {:retrieve, key}
      [_, key, value] -> {:insert, key, value}
      unknown -> {:error, unknown}
    end
  end

  defp parse(message), do: {:error, message}

  defp retrieve(_db, "version"), do: "version=SwigServer 0.1"
  defp retrieve(db, key), do: "#{key}=#{Map.get(db, key)}" |> IO.inspect()

  defp insert(db, "version", _key), do: db
  defp insert(db, key, value), do: Map.put(db, key, value)
end
