defmodule Exalted.LogReader.Naive.Parser do
  def parse(record) do
    {:ok, record}
  end

  def parse!(record) do
    case parse(record) do
      {:ok, v} -> v
      {:error, e} -> raise e
    end
  end
end
