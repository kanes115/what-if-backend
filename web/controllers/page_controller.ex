defmodule WhatIf.PageController do
  use WhatIf.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
