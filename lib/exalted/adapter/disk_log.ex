defmodule Exalted.LogReader.Adapter.DiskLog do
  use Exalted.LogReader.Adapter

  @impl true
  def init(opts) do
    id = Keyword.get(opts, :id, UUID.uuid1())

    case :disk_log.open(name: id, file: String.to_charlist(id_to_filepath(id))) do
      {:ok, ref} -> {:ok, ref}
      {:error, reason} -> {:stop, reason}
    end
  end

  @impl true
  def terminate(_reason, ref) do
    :disk_log.close(ref)
  end

  @impl true
  def get_state(ref) do
    ref
  end

  @impl true
  def handle_record(record, index, log) do
    :disk_log.log(log, {index, record})
    log
  end

  def id_to_filepath(id), do: "priv/static/logs/#{id}.log"
end
