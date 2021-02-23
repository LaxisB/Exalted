defmodule Exalted.LogReader.Adapter.Dummy do
  use Exalted.LogReader.Adapter

  @impl true
  def init([]) do
    {:ok, []}
  end

  @impl true
  def terminate(_reason, _state) do
  end

  @impl true
  def get_state(_state) do
    []
  end

  @impl true
  def handle_record(_record, _index, _state) do
  end
end
