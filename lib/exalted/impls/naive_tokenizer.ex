defmodule Exalted.LogReader.NaiveTokenizer do
  @moduledoc """
  tokenizes a line in the combatlog. The log has one record per line with the following general structure of `<timestamp> <event>,<values>`
  where:

  NonTerminals:
  | type          | children         | comment |
  | ------------- | ---------------- | ------- |
  | values        | `value`          | single value       |
  | values        | `value`,`values` | list of values     |
  | value         | (`values`)       | a nested list      |
  | value         | [`values`]       | also a nested list |
  | value         | `uid`            |                    |
  | value         | `constant`       |                    |
  | value         | `integer`        |                    |
  | value         | `mask`           |                    |
  | value         | `string`         |                    |

  Terminals:
  | type      | format                               | comment                                                     |
  | --------- | ------------------------------------ | ----------------------------------------------------------- |
  | timestamp | \d{2}\/\d{2} \d{2}:\d{2}:\d{2}.\d{3} | uses the format of month/day hour:minute:second:millisecond |
  | event     | [A-Z](_[A-Z])*                       | defines the schema of `values`                              |
  | uid       | Player-\d+-\d+                       | uniquely identifies a player                                |
  | uid       | Creature-\d+                         |                                                             |
  | constant  | [A-Z](_[A-Z])*                       | not used for display                                        |
  | integer   | \d*                                  |                                                             |
  | mask      | 0x\d+                                | a bitmask                                                   |
  | string    | \"\S+\"                              | quoted string. used for names etc                           |
  """

  require IEx

  def tokenize(<<date::binary-size(17), "  ", rest::binary>>) do
    values =
      rest
      |> String.replace(parens_open(), "[")
      |> String.replace(parens_close(), "]")
      |> String.replace("[", "[,")
      |> String.replace("]", ",]")
      |> String.split(value_separator())
      |> Enum.filter(&(&1 != ""))
      |> tokenize_values()

    case values do
      [event | payload] -> {:ok, {date, event, payload}}
      rest -> {:error, "bad values", {date, rest}}
    end
  end

  def tokenize("") do
    {:ok, {}}
  end

  def tokenize!(record) do
    case tokenize(record) do
      {:ok, v} -> v
      {:error, e} -> raise e
    end
  end

  defp tokenize_values(values) when is_list(values) do
    tokenize_values({values, 0, %{}, []})
  end

  defp tokenize_values({[], _, _, parsed}) do
    Enum.reverse(parsed)
  end

  defp tokenize_values({remaining, depth, state, parsed}) do
    {item, rest} =
      case remaining do
        [i] -> {i, []}
        [i | r] -> {i, r}
      end

    case {String.starts_with?(item, "["), String.ends_with?(item, "]"), depth} do
      # ( :: start of group. push a list to add children into
      {true, false, _} ->
        tokenize_values({rest, depth + 1, Map.put(state, depth + 1, []), parsed})

      # ) ::  end of nested group. push into lower level
      {false, true, n} when n > 1 ->
        {items, new_state} = Map.pop(state, depth)
        new_state = Map.update(new_state, n - 1, [], &[items | &1])
        tokenize_values({rest, depth - 1, new_state, parsed})

      # ) :: end of group. push to result
      {false, true, n} when n > 0 ->
        {items, new_state} = Map.pop(state, depth)

        tokenize_values({rest, depth - 1, new_state, [Enum.reverse(items) | parsed]})

      # ) :: bad depth
      {false, true, n} when n < 0 ->
        []

      # item :: in a group. push value on top of the current group
      {false, false, n} when n > 0 ->
        item_token = tokenize_value(item)
        tokenize_values({rest, depth, Map.update(state, depth, [], &[item_token | &1]), parsed})

      # item :: not in a group. just add the val
      {false, false, _} ->
        item_token = tokenize_value(item)
        tokenize_values({rest, depth, state, [item_token | parsed]})

      {_, _, _} ->
        nil
    end
  end

  defp tokenize_value("BNetAccount-" <> _rest = value) do
    {:guid, value}
  end

  defp tokenize_value("Creature-" <> _rest = value) do
    {:guid, value}
  end

  defp tokenize_value("GameObject-" <> _rest = value) do
    {:guid, value}
  end

  defp tokenize_value("Pet-" <> _rest = value) do
    {:guid, value}
  end

  defp tokenize_value("Player-" <> _rest = value) do
    {:guid, value}
  end

  defp tokenize_value("Vehicle-" <> _rest = value) do
    {:guid, value}
  end

  defp tokenize_value("Vignette-" <> _rest = value) do
    {:guid, value}
  end

  # handle inlined strings
  defp tokenize_value("\"" <> _ = value) do
    case String.ends_with?(value, "\"") do
      true -> {:string, String.slice(value, 1..-2)}
      false -> {:unknown, value}
    end
  end

  # handle bitmasks
  defp tokenize_value("0x" <> rest = value) do
    case String.match?(value, match_mask()) do
      true ->
        {masked_value, _} = Integer.parse(rest, 16)
        {:mask, masked_value}

      false ->
        {:unknown, value}
    end
  end

  defp tokenize_value(value) do
    case {Integer.parse(value, 10), String.match?(value, match_constant())} do
      {{value, ""}, _} -> {:integer, value}
      {_, true} -> {:constant, value}
      _ -> {:unknown, value}
    end
  end

  def record_separator, do: :binary.compile_pattern("\n")
  def value_separator, do: :binary.compile_pattern(",")
  def parens_open, do: :binary.compile_pattern("(")
  def parens_close, do: :binary.compile_pattern(")")
  def match_mask, do: Regex.compile!("0x[a-f0-f]+")
  def match_constant, do: Regex.compile!("[A-Z](_[A-Z])*")
end
