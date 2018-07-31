defmodule Jamdb.Oracle.Result do
  @moduledoc """
  Result struct returned from any successful query. Its fields are:
    * `columns` - The names of each column in the result set;
    * `rows` - The result set. A list of tuples, each tuple corresponding to a
                row, each element in the tuple corresponds to a column;
    * `num_rows` - The number of fetched or affected rows;
  """

  @type t :: %__MODULE__{
    columns:  [String.t] | nil,
    rows:     [[term] | binary] | nil,
    num_rows: integer | :undefined}

  defstruct [columns: nil, rows: nil, num_rows: :undefined]
end

defmodule Jamdb.Oracle.Cursor do
  @moduledoc """
  Cursor struct used for query. Its fields are:
    * `cursor` - The cursor id;
    * `params` - The parameters as given to query;
    * `row_format` - The row format data;
    * `last_row` - The last row of fetched data;
  """
  
  @type t :: %__MODULE__{
    cursor:  integer | nil,
    params: any,
    row_format: any,
    last_row: any}

  defstruct [cursor: nil, params: nil, row_format: nil, last_row: nil]
end
