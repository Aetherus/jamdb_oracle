defmodule Ecto.Adapters.Jamdb.Oracle do
  @moduledoc """
  Ecto adapter for Oracle.

  It uses `Jamdb.Oracle` for communicating to the database
  and a connection pool, such as `poolboy`.

  ## Features

   * Using prepared statement functionality, the SQL statement you want
     to run is precompiled and stored in a database object, and you can run it
     as many times as required without compiling it every time it is run. If the data in the
     statement changes, you can use bind variables as placeholders for the data and then 
     provide literal values at run time.

   * Using bind variables:

      `{"select 1+:1, sysdate, rowid from dual where 1=:1"`, `[1]}`
   * Calling stored procedure:

      `{"begin proc(:1, :2, :3); end;"`, `[1.0, 2.0, 3.0]}`
   * Calling stored function:

      `{"begin :1 := func(:2); end;"`, `["", "one hundred"]}`
   * Using cursor variable:

      `{"begin open :1 for select * from tabl where dat>:2; end;"`, `[:cursor, {2016, 8, 1}]}`
   * Using returning clause:

      `{"insert into tabl values (tablid.nextval, sysdate) return id into :1"`, `[{:out, 0}]}`

      `Repo.insert_all(Post,[[id: 100]], returning: [:created_at, out: {2016, 8, 1}])`
   * Update batching:

      `{:batch, "insert into tabl values (:1, :2, :3)"`, `[[1, 2, 3],[4, 5, 6],[7, 8, 9]]}`
   * Row prefetching:

      `{:fetch, "select * from tabl where id>:1"`, `[1]}`
      
      `{:fetch, cursor, rowformat, lastrow}`

  ## Options

  Adapter options split in different categories described
  below. All options should be given via the repository
  configuration. These options are also passed to the module
  specified in the `:pool` option, so check that module's
  documentation for more options.

  ### Compile time options

  Those options should be set in the config file and require
  recompilation in order to make an effect.

    * `:adapter` - The adapter name, in this case, `Ecto.Adapters.Jamdb.Oracle`
    * `:name`- The name of the Repo supervisor process
    * `:pool` - The connection pool module, defaults to `DBConnection.Poolboy`
    * `:pool_timeout` - The default timeout to use on pool calls, defaults to `5000`

  ### Connection options

    * `:hostname` - Server hostname (Name or IP address of the database server)
    * `:port` - Server port (Number of the port where the server listens for requests)
    * `:database` - Database (Database service name or SID with colon as prefix)
    * `:username` - Username (Name for the connecting user)
    * `:password` - User password (Password for the connecting user)
    * `:parameters` - Keyword list of connection parameters
    * `:socket_options` - Options to be given to the underlying socket
    * `:timeout` - The default timeout to use on queries, defaults to `15000`
    * `:charset` - Name that is used in multibyte encoding

  ### Connection parameters

    * `:autocommit` - Mode that issued an automatic COMMIT operation
    * `:fetch` - Number of rows to fetch from the server
    * `:role` - Mode that is used in an internal logon
    * `:prelim` - Mode that is permitted when the database is down

  ### Primitive types

  The primitive types are:

  Ecto types              | Oracle types                     | Literal syntax in params
  :---------------------- | :------------------------------- | :-----------------------
  `:id`, `:integer`       | `NUMBER (*,0)`                   | 1, 2, 3
  `:float`                | `NUMBER`,`FLOAT`,`BINARY_FLOAT`  | 1.0, 2.0, 3.0
  `:decimal`              | `NUMBER`,`FLOAT`,`BINARY_FLOAT`  | [`Decimal`](https://hexdocs.pm/decimal)
  `:string`, `:binary`    | `CHAR`, `VARCHAR2`, `CLOB`       | "one hundred"
  `:string`, `:binary`    | `NCHAR`, `NVARCHAR2`, `NCLOB`    | "百元", "万円"
  `{:array, :integer}`    | `RAW`, `BLOB`                    | 'E799BE'
  `:naive_datetime`       | `DATE`, `TIMESTAMP`              | {2016, 8, 1}, {{2016, 8, 1}, {13, 14, 15}}
  `:utc_datetime`         | `TIMESTAMP WITH TIME ZONE`       | [`DateTime`](https://hexdocs.pm/elixir)

  #### Examples

      iex> Ecto.Adapters.SQL.query(Repo, "select 1+:1, sysdate, rowid from dual where 1=:1 ", [1])
      {:ok, %{num_rows: 1, rows: [[2, {{2016, 8, 1}, {13, 14, 15}}, "AAAACOAABAAAAWJAAA"]]}}

  """

  use Ecto.Adapters.SQL, Jamdb.Oracle
  
  @behaviour Ecto.Adapter.Storage
  @behaviour Ecto.Adapter.Structure

  @doc false
  def storage_up(_opts), do: err
  
  @doc false
  def storage_down(_opts), do: err
  
  @doc false
  def structure_dump(_default, _config), do: err
  
  @doc false
  def structure_load(_default, _config), do: err
  
  @doc false
  def supports_ddl_transaction? do
    false
  end
  
  defp err, do: {:error, false}

end
