defmodule Jamdb.Oracle do
  @moduledoc """
  Interface for interacting with Oracle driver for Erlang.

  It implements `DBConnection` behaviour, using `:jamdb_oracle` to connect to the
  database.
  """

  alias Jamdb.Oracle.Query
  alias Jamdb.Oracle.Result
  alias Jamdb.Oracle.Type

  @doc """
  Connect to the database.
  """
  @spec start_link(Keyword.t) :: {:ok, pid}
  def start_link(opts) do
    DBConnection.start_link(Jamdb.Oracle.Protocol, opts)
  end

  @doc """
  Executes a query against an Oracle driver for Erlang.
  """
  @spec query(pid(), binary(), [Type.param()], Keyword.t) ::
    {:ok, iodata(), Result.t}
  def query(conn, statement, params, opts \\ []) do
    DBConnection.prepare_execute(
      conn, %Query{name: "", statement: statement}, params, opts)
  end

  @doc """
  Executes a query against an Oracle driver for Erlang.

  Raises an error on failure. See `query/4` for details.
  """
  @spec query!(pid(), binary(), [Type.param()], Keyword.t) ::
    {iodata(), Result.t}
  def query!(conn, statement, params, opts \\ []) do
    DBConnection.prepare_execute!(
      conn, %Query{name: "", statement: statement}, params, opts)
  end
end
