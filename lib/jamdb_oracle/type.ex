defmodule Jamdb.Oracle.Type do
  @moduledoc """
  Type conversions.
  """

  @doc """
  Transforms input params into `:jamdb_oracle` params.
  """
  @spec encode(value :: any(), opts :: Keyword.t) :: any()
  def encode(nil, _), do: :null
  def encode(%Decimal{} = decimal, _), do: Decimal.to_float(decimal)
  def encode(%Ecto.Query.Tagged{value: value}, _), do: value
  def encode(value, opts) when is_binary(value) do
    if Keyword.has_key?(opts, :charset) and 
      Enum.member?(["al16utf16","ja16euc","zhs16gbk","zht16big5","zht16mswin950"],
        opts[:charset]) do
      value |> to_charlist
    else
      value
    end
  end
  def encode(value, _), do: value
  
  @doc """
  Transforms `:jamdb_oracle` return values to Elixir representations.
  """
  @spec decode(any(), opts :: Keyword.t) :: any()
  def decode(:null, _), do: nil
  def decode({value}, _) when is_number(value), do: value
  def decode({date, time}, _) when is_tuple(date), do: to_naive({date, time})
  def decode({date, time, tz}, _) when is_tuple(date) and is_list(tz), do: to_utc({date, time, tz})
  def decode({date, time, _}, _) when is_tuple(date), do: to_naive({date, time})
  def decode(value, _) when is_list(value), do: to_binary(value)
  def decode(value, _), do: value

  defp expr(list) when is_list(list) do
    Enum.map(list, fn 
      :null -> nil
      elem  -> elem
    end)
  end

  defp to_binary(list) when is_list(list) do
    try do
      :binary.list_to_bin(list)
    rescue
      ArgumentError ->
        Enum.map(expr(list), fn
          elem when is_list(elem) -> expr(elem)
          other -> other
        end) |> Enum.join
    end
  end

  defp to_naive({{year, mon, day}, {hour, min, sec}}) when is_integer(sec),
    do: {{year, mon, day}, {hour, min, sec}}
  defp to_naive({{year, mon, day}, {hour, min, sec}}),
    do: {{year, mon, day}, parse_time({hour, min, sec})}

  defp to_utc({date, time, tz}) do
    {hour, min, sec, usec} = parse_time(time)
    offset = parse_offset(to_string(tz))
    seconds = :calendar.datetime_to_gregorian_seconds({date, {hour, min, sec}})
    {{year, mon, day}, {hour, min, sec}} = :calendar.gregorian_seconds_to_datetime(seconds + offset)

    %DateTime{year: year, month: mon, day: day, hour: hour, minute: min, second: sec,
     microsecond: {usec, 6}, std_offset: 0, utc_offset: 0, zone_abbr: "UTC", time_zone: to_string(tz)}
  end

  defp parse_time({hour, min, sec}),
    do: {hour, min, trunc(sec), trunc((sec - trunc(sec)) * 1000000)}

  defp parse_offset(tz) do
    case Calendar.ISO.parse_offset(tz) do
      {offset, ""} when is_integer(offset) -> offset
      _ -> 0
    end
  end

end
