defmodule Jamdb.Oracle.Query do
  @moduledoc """
  Implementation of `DBConnection.Query` for `Jamdb.Oracle`.
  """

  @type t :: %__MODULE__{
    name: iodata,
    statement: iodata,
    columns: [String.t] | nil
  }

  defstruct [:name, :statement, :columns]
end

defimpl DBConnection.Query, for: Jamdb.Oracle.Query do

  alias Jamdb.Oracle.Query
  alias Jamdb.Oracle.Result
  alias Jamdb.Oracle.Type

  @spec parse(query :: Query.t, opts :: Keyword.t) :: Query.t
  def parse(query, _opts), do: query

  @spec describe(query :: Query.t, opts :: Keyword.t) :: Query.t
  def describe(query, _opts), do: query

  @spec encode(query :: Query.t,
    params :: [Type.param()], opts :: Keyword.t) :: [Type.param()]
  def encode(_, [], _), do: []
  def encode(_, params, opts) do
    Enum.map(params, &(Type.encode(&1, opts)))
  end

  @spec decode(query :: Query.t, result :: Result.t, opts :: Keyword.t) ::
    Result.t
  def decode(_, %Result{rows: []} = result, _), do: result
  def decode(_, %Result{rows: rows} = result, opts) when not is_nil(rows) do
    Map.put(result, :rows, Enum.map(rows, fn row -> Enum.map(row, &(Type.decode(&1, opts))) end))
  end
  def decode(_, result, _), do: result
end

defimpl String.Chars, for: Jamdb.Oracle.Query do
  def to_string(%Jamdb.Oracle.Query{statement: statement}) do
    IO.iodata_to_binary(statement)
  end
end
