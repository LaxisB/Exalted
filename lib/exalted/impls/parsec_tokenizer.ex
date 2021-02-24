defmodule Exalted.LogReader.ParsecTokenizer do
  import NimbleParsec
  alias Exalted.LogReader.NaiveTokenizer

  defcombinatorp(
    :quoted_value,
    ignore(string("\"")) |> utf8_string([{:not, ?"}], min: 1) |> ignore(string("\""))
  )

  defcombinatorp(
    :timestamp,
    integer(min: 1, max: 2)
    |> ignore(string("/"))
    |> integer(min: 1, max: 2)
    |> ignore(string(" "))
    |> integer(2)
    |> ignore(string(":"))
    |> integer(2)
    |> ignore(string(":"))
    |> integer(2)
    |> ignore(string("."))
    |> integer(3)
    |> tag(:timestamp)
    |> map({:parse_token, []})
  )

  defcombinatorp(
    :event_literal,
    utf8_string([?A..?Z, ?_], min: 1)
    |> tag(:event)
    |> map({:parse_token, []})
  )

  defcombinatorp(
    :value_literal,
    choice([
      parsec(:quoted_value) |> tag(:quoted_value) |> map({:parse_token, []}),
      utf8_string([{:not, ?,}], min: 1)
      |> tag(:raw_value)
      |> map({:parse_token, []})
    ])
  )

  defcombinatorp(
    :group,
    ignore(string("("))
    |> repeat(parsec(:value) |> ignore(optional(string(","))))
    |> ignore(string(")"))
    |> tag(:group)
    |> map({:parse_token, []})
  )

  defcombinatorp(
    :value,
    choice([
      parsec(:group),
      parsec(:value_literal)
    ])
  )

  defcombinatorp(
    :payload,
    repeat(
      lookahead_not(eos())
      |> ignore(string(","))
      |> parsec(:value)
    )
    |> tag(:values)
    |> map(:parse_token)
  )

  line =
    parsec(:timestamp)
    |> ignore(string("  "))
    |> parsec(:event_literal)
    |> parsec(:payload)
    |> eos()
    |> tag(:line)
    |> map(:parse_line)

  defparsec(:parse, line, inline: true)

  def tokenize(blob) do
    blob
    |> String.replace(NaiveTokenizer.parens_open(), "[")
    |> String.replace(NaiveTokenizer.parens_close(), "]")
    |> parse()
    |> elem(1)
    |> List.first()
  end

  def parse_line({:line, [time, event, vals]}) do
    {time, event, vals}
  end

  def parse_token({:values, vals}) do
    vals
  end

  def parse_token({:timestamp, [_month, _day, hour, minute, second, millisecond]}) do
    {:ok, time} = Time.from_erl({hour, minute, second}, {millisecond * 1000, 3})
    time
  end

  def parse_token({:group, value}) do
    value
  end

  def parse_token({:event, [value]}) do
    {:constant, value}
  end

  def parse_token({:quoted_value, [val]}), do: {:string, val}

  def parse_token({:raw_value, [val]}) do
    parse_raw_value(val)
  end

  defp parse_raw_value("Player-" <> _ = value) do
    {:guid, value}
  end

  defp parse_raw_value("Item-" <> _ = value) do
    {:guid, value}
  end

  defp parse_raw_value("BNetAccount-" <> _ = value) do
    {:guid, value}
  end

  defp parse_raw_value("Creature-" <> _ = value) do
    {:guid, value}
  end

  defp parse_raw_value("Pet-" <> _ = value) do
    {:guid, value}
  end

  defp parse_raw_value("GameObject-" <> _ = value) do
    {:guid, value}
  end

  defp parse_raw_value("Vehicle-" <> _ = value) do
    {:guid, value}
  end

  defp parse_raw_value("Vignette-" <> _ = value) do
    {:guid, value}
  end

  defp parse_raw_value("0x" <> value) do
    {parsed, _} = Integer.parse(value, 16)
    {:mask, parsed}
  end

  defp parse_raw_value(value) do
    case Integer.parse(value) do
      {int, ""} -> {:integer, int}
      _ -> {:unknown, value}
    end
  end
end
