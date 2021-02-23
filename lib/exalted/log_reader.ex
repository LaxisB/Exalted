defmodule Exalted.LogReader do
  alias Exalted.LogReader.Tokenizer

  def read(blob) do
    target = :ets.new(:tmp, [:ordered_set, :public])
    read(blob, 0, target)
  end

  def read(blob, offset, table) do
    [blob]
    |> Stream.flat_map(&String.split(&1, Tokenizer.record_separator()))
    |> Stream.filter(&(&1 != ""))
    |> Stream.with_index()
    |> Flow.from_enumerable()
    |> Flow.partition()
    |> Flow.map(fn {v, i} -> {i + offset, Tokenizer.tokenize!(v)} end)
    |> Flow.map(fn val -> :ets.insert(table, val) end)
    |> Flow.run()

    table
  end
end
