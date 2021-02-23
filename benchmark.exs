alias Exalted.LogReader

argv = System.argv()
target = 4_000_000

file =
  case argv do
    [f] ->
      f

    [f | _] ->
      f

    _ ->
      IO.puts("please pass this script a file ")
      Process.exit(self(), "bad_input")
  end

raw_list =
  File.read!(file)
  |> String.split(~r/\R/, trim: true)

inputs =
  1..(div(target, length(raw_list)) + 1)
  |> Enum.to_list()
  |> Enum.flat_map(fn _ -> raw_list end)

# warm up with 100k lines
inputs
|> Stream.take(100_000)
|> Flow.from_enumerable()
|> Flow.map(fn list ->
  [
    LogReader.read_naive(list, LogReader.Adapter.Dummy),
    LogReader.read_parsec(list, LogReader.Adapter.Dummy)
  ]
end)
|> Flow.run()

Benchee.run(
  %{
    "custom implementation" => fn count ->
      inputs
      |> Enum.take(count)
      |> LogReader.read_naive(LogReader.Adapter.Dummy)
    end,
    "NimbleParsec" => fn count ->
      inputs
      |> Enum.take(count)
      |> LogReader.read_parsec(LogReader.Adapter.Dummy)
    end
  },
  warmup: 0,
  time: 60,
  inputs: %{
    "10000 rows" => 10_000,
    "100000 rows" => 100_000,
    "1000000 rows" => 1_000_000
  },
  load: "#{file}.benchee",
  save: [
    path: "#{file}.benchee"
  ]
)
