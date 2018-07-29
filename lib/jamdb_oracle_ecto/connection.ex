defmodule Ecto.Adapters.Jamdb.Oracle.Connection do
  @moduledoc false

  @behaviour Ecto.Adapters.SQL.Connection
  
  alias Ecto.Adapters.Jamdb.Oracle.Query
  
  def child_spec(opts) do
    DBConnection.child_spec(Jamdb.Oracle.Protocol, opts)
  end
  
  def execute(conn, %Jamdb.Oracle.Query{} = query, params, opts) do
    case DBConnection.prepare_execute(conn, query, params, opts) do
      {:ok, _, result} -> {:ok, result}
      {:error, err} -> raise err
    end
  end
  def execute(conn, statement, params, opts) do
    query = %Jamdb.Oracle.Query{statement: statement}
    case DBConnection.prepare_execute(conn, query, params, opts) do
      {:ok, _, result} -> {:ok, result}
      {:error, err} -> raise err
    end
  end

  def prepare_execute(conn, _name, statement, params, opts) do
    query = %Jamdb.Oracle.Query{statement: statement}
    case DBConnection.prepare_execute(conn, query, params, opts) do
      {:ok, _, _} = ok -> ok
      {:error, err} -> raise err
    end
  end
    
  def stream(conn, statement, params, opts) do
    query = %Jamdb.Oracle.Query{statement: statement}
    DBConnection.stream(conn, query, params, opts)
  end
  
  defdelegate all(query), to: Query
  defdelegate update_all(query), to: Query
  defdelegate delete_all(query), to: Query
  defdelegate insert(prefix, table, header, rows, on_conflict, returning), to: Query
  defdelegate update(prefix, table, fields, filters, returning), to: Query
  defdelegate delete(prefix, table, filters, returning), to: Query

  def to_constraints(_err), do: []
  
  def execute_ddl(err), do: raise %Jamdb.Oracle.Error{message: to_string(err)}
  
end
