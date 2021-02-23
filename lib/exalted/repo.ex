defmodule Exalted.Repo do
  use Ecto.Repo,
    otp_app: :exalted,
    adapter: Ecto.Adapters.Postgres
end
