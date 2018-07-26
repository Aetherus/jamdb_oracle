defmodule Ecto.Adapters.Jamdb.Oracle.Helpers do
  @moduledoc false

  def quote_qualified_name(name, sources, ix) do
    {_, source, _} = elem(sources, ix)
    [source, ?. | quote_name(name)]
  end

  def quote_name(name) when is_atom(name) do
    quote_name(Atom.to_string(name))
  end
  def quote_name(name) do
    if String.contains?(name, "\"") do
      error!(nil, "bad field name #{inspect name}")
    end
    [name]
  end

  def quote_table(nil, name),    do: quote_table(name)
  def quote_table(prefix, name), do: [quote_table(prefix), ?., quote_table(name)]

  def quote_table(name) when is_atom(name),
    do: quote_table(Atom.to_string(name))
  def quote_table(name) do
    if String.contains?(name, "\"") do
      error!(nil, "bad table name #{inspect name}")
    end
    [name]
  end

  def intersperse_map(list, separator, mapper, acc \\ [])
  def intersperse_map([], _separator, _mapper, acc),
    do: acc
  def intersperse_map([elem], _separator, mapper, acc),
    do: [acc | mapper.(elem)]
  def intersperse_map([elem | rest], separator, mapper, acc),
    do: intersperse_map(rest, separator, mapper, [acc, mapper.(elem), separator])

  def intersperse_reduce(list, separator, user_acc, reducer, acc \\ [])
  def intersperse_reduce([], _separator, user_acc, _reducer, acc),
    do: {acc, user_acc}
  def intersperse_reduce([elem], _separator, user_acc, reducer, acc) do
    {elem, user_acc} = reducer.(elem, user_acc)
    {[acc | elem], user_acc}
  end
  def intersperse_reduce([elem | rest], separator, user_acc, reducer, acc) do
    {elem, user_acc} = reducer.(elem, user_acc)
    intersperse_reduce(rest, separator, user_acc, reducer, [acc, elem, separator])
  end

  def escape_string(value) when is_list(value) do
    escape_string(:binary.list_to_bin(value))
  end
  def escape_string(value) when is_binary(value) do
    :binary.replace(value, "'", "''", [:global])
  end

  def error!(nil, msg) do
    raise ArgumentError, msg
  end
  def error!(query, msg) do
    raise Ecto.QueryError, query: query, message: msg
  end
  
end

