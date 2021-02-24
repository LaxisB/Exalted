defmodule Exalted.LogReader.Adapter.ETS do
  @behaviour Exalted.LogReader.Adapter

  @impl true
  def init([]) do
    Agent.start(fn ->
      :ets.new(:parse_results, [
        :ordered_set,
        :compressed,
        :public,
        {:read_concurrency, true},
        {:write_concurrency, true}
      ])
    end)
  end

  @impl true
  def terminate(_reason, table) do
    Agent.update(table, fn ref -> :ets.delete(ref) end)
    Agent.stop(table)
  end

  @impl true
  def get_state(table) do
    Agent.get(table, fn ref -> :ets.tab2list(ref) end)
  end

  @impl true
  def handle_record(record, index, table) do
    Agent.update(table, fn ref ->
      :ets.insert(ref, {index, record})
      ref
    end)

    table
  end
end
