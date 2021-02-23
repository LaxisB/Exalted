defmodule Exalted.LogReader.Adapter.ETS do
  use Exalted.LogReader.Adapter

  @impl true
  def init([]) do
    {:ok, :ets.new(:ets_adapter, [:ordered_set])}
  end

  @impl true
  def terminate(_reason, state) do
    :ets.delete(state)
  end

  @impl true
  def get_state(state) do
    :ets.tab2list(state)
  end

  @impl true
  def handle_record(record, index, table) do
    :ets.insert(table, {index, record})
    table
  end
end
