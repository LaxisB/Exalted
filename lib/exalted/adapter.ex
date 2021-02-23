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

  defmacro __using__(_opts) do
    quote do
      @behaviour Exalted.LogReader.Adapter

      def handle_call(:get_state, _from, state) do
        value = get_state(state)
        {:reply, value, state}
      end

      def handle_cast({:handle_record, value, offset}, state) do
        new_state = handle_record(value, offset, state)
        {:noreply, new_state}
      end
    end
  end
end
