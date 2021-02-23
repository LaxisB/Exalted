defmodule ExaltedWeb.PageController do
  use ExaltedWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
