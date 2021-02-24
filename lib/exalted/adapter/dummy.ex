defmodule Exalted.LogReader.Adapter.Dummy do
  @moduledoc """
  A Dummy Adapter that basically thows away everything it receives. Used purely for benchmarking the parser
  """
  alias Exalted.LogReader.Adapter
  @behaviour Adapter

  @impl Adapter
  def init([]) do
    {:ok, []}
  end

  @impl Adapter
  def terminate(_reason, _state) do
  end

  @impl Adapter
  def get_state(_state) do
    []
  end

  @impl Adapter
  def handle_record(_record, _index, _state) do
  end
end
