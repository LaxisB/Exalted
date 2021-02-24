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
    {adapter, args} =
      case callback do
        {module, args} -> {module, args}
        module -> {module, [[]]}
      end

    {:ok, adapter_state} = apply(adapter, :init, args)

    items =
      case is_binary(blob) do
        true -> [blob]
        false -> blob
      end

    end_state =
      items
      |> Stream.flat_map(&String.split(&1, NaiveTokenizer.record_separator()))
      |> Stream.filter(&(&1 != ""))
      |> Stream.with_index()
      |> Flow.from_enumerable()
      |> Flow.partition()
      |> Flow.map(fn {v, i} -> {ParsecTokenizer.tokenize(v), i} end)
      |> Flow.reduce(fn -> adapter_state end, fn {v, i}, s ->
        # use call to prevent race conditions
        new_state = apply(adapter, :handle_record, [v, i, s])
        new_state
      end)
      |> Flow.emit(:state)
      |> Enum.to_list()
      |> List.last()

    res = apply(adapter, :get_state, [end_state])
    apply(adapter, :terminate, [:normal, end_state])

    res
  end
end
