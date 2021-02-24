defmodule Exalted.LogReader.Adapter do
  @callback init(init_arg :: term) ::
              {:ok, state}
              | {:ok, state, timeout | :hibernate | {:continue, term}}
              | :ignore
              | {:stop, reason :: any}
            when state: any
  @callback terminate(reason, state :: term) :: term
            when reason: :normal | :shutdown | {:shutdown, term}

  @callback get_state(state :: term) :: term
  @callback handle_record(record :: term, index :: integer(), state :: term) :: term
end
