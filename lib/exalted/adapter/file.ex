defmodule Exalted.LogReader.Adapter.File do
  use Exalted.LogReader.Adapter

  @impl true
  def init(opts) do
    with {:ok, name} <- Keyword.fetch(opts, :name),
         {:ok, handle} <- File.open(name, [:read, :write, :utf8]) do
      {:ok, {handle, name}}
    else
      _ -> {:stop, "failed to init file adapter"}
    end
  end

  @impl true
  def terminate(_reason, {handle, _}) do
    File.close(handle)
  end

  @impl true
  def get_state({_, name}) do
    File.stream!(name)
    |> Enum.map(&Jason.decode!(&1))
  end

  @impl true
  def handle_record(record, _index, {handle, _} = state) do
    :ok = IO.write(handle, Jason.encode!(record) <> "\n")
    state
  end
end

defmodule Jason.TupleEncoder do
  defimpl Jason.Encoder, for: Tuple do
    def encode(value, opts) do
      value
      |> Tuple.to_list()
      |> Jason.Encoder.List.encode(opts)
    end
  end
end
