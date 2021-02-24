defmodule Exalted.LogReader do
  alias Exalted.LogReader.NaiveTokenizer
  alias Exalted.LogReader.ParsecTokenizer

  def read_naive(blob, callback) do
    {m, a} =
      case callback do
        {module, args} -> {module, args}
        module -> {module, []}
      end

    {:ok, pid} = GenServer.start_link(m, a)

    items =
      case is_list(blob) do
        true -> blob
        false -> [blob]
      end

    items
    |> Stream.flat_map(&String.split(&1, NaiveTokenizer.record_separator()))
    |> Stream.filter(&(&1 != ""))
    |> Stream.with_index()
    |> Flow.from_enumerable()
    |> Flow.partition()
    |> Flow.map(fn {v, i} -> {NaiveTokenizer.tokenize!(v), i} end)
    |> Flow.map(fn {v, i} ->
      GenServer.cast(pid, {:handle_record, v, i})
    end)
    |> Flow.run()

    value = GenServer.call(pid, :get_state)

    GenServer.stop(pid)

    value
  end

  def read_parsec(blob, callback) do
    {m, a} =
      case callback do
        {module, args} -> {module, args}
        module -> {module, []}
      end

    {:ok, pid} = GenServer.start_link(m, a)

    items =
      case is_binary(blob) do
        true -> [blob]
        false -> blob
      end

    items
    |> Stream.flat_map(&String.split(&1, NaiveTokenizer.record_separator()))
    |> Stream.filter(&(&1 != ""))
    |> Stream.with_index()
    |> Flow.from_enumerable()
    |> Flow.partition()
    |> Flow.map(fn {v, i} -> {ParsecTokenizer.tokenize(v), i} end)
    |> Flow.map(fn {v, i} ->
      # use call to prevent race conditions
      GenServer.call(pid, {:handle_record, v, i})
    end)
    |> Flow.run()

    value = GenServer.call(pid, :get_state)
    GenServer.stop(pid)
    value
  end
end
