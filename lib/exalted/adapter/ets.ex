defmodule Exalted.LogReader.Adapter.ETS do
  use Exalted.LogReader.Adapter

  @impl true
  def init([]) do
    s =
      :ets.new(:parse_results, [
        :ordered_set,
        :compressed,
        :public,
        {:read_concurrency, true},
        {:write_concurrency, true}
      ])

    {:ok, s}
  end

  @impl true
  def terminate(_reason, table) do
    :ets.delete(table)
  end

  @impl true
  def get_state(table) do
    :ets.tab2list(table)
  end

  @impl true
  def handle_record(record, index, table) do
    :ets.insert(table, {index, record})
    table
  end
end
