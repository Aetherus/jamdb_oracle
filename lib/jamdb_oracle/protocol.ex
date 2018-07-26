defmodule Jamdb.Oracle.Protocol do
  @moduledoc """
  Implementation of `DBConnection` behaviour for `Jamdb.Oracle`.
  """

  @behaviour DBConnection

  alias Jamdb.Oracle.Query
  alias Jamdb.Oracle.Result
  alias Jamdb.Oracle.Error

  defstruct [pid: nil, ora: :idle, conn_opts: []]

  @typedoc """
  Process state.

  Includes:

  * `:pid`: the pid of the driver process
  * `:ora`: the transaction state. Can be `:idle` (not in a transaction),
    `:transaction` (in a transaction) or `:auto_commit` (connection in
    autocommit mode)
  * `:conn_opts`: the options used to set up the connection.
  """
  @type state :: %__MODULE__{pid: pid(),
                             ora: :idle | :transaction | :auto_commit,
                             conn_opts: Keyword.t}

  @type query :: Query.t
  @type params :: [any]
  @type result :: Result.t
  @type cursor :: any

  @doc false
  @spec connect(opts :: Keyword.t) :: {:ok, state}
                                    | {:error, Exception.t}
  def connect(opts) do
    database = Keyword.fetch!(opts, :database) |> to_charlist
    env = if( hd(database) == ?:, do: [sid: tl(database)], else: [service_name: database] )
    |> Keyword.put_new(:host, Keyword.fetch!(opts, :hostname) |> to_charlist)
    |> Keyword.put_new(:port, Keyword.fetch!(opts, :port))
    |> Keyword.put_new(:user, Keyword.fetch!(opts, :username) |> to_charlist)
    |> Keyword.put_new(:password, Keyword.fetch!(opts, :password) |> to_charlist)
    |> Keyword.put_new(:timeout, Keyword.fetch!(opts, :timeout))
    params = if( Keyword.has_key?(opts, :parameters) == true,
      do: opts[:parameters], else: [] )
    sock_opts = if( Keyword.has_key?(opts, :socket_options) == true,
      do: [socket_options: opts[:socket_options]], else: [] )
    case :jamdb_oracle.start_link(sock_opts ++ params ++ env) do
      {:ok, pid} -> {:ok, %__MODULE__{
                        pid: pid,
                        conn_opts: opts,
                        ora: if(params[:autocommit] == 0,
                          do: :idle,
                          else: :auto_commit)
                     }}
      response -> response
    end
  end

  @doc false
  @spec disconnect(err :: Exception.t, state) :: :ok
  def disconnect(_err, %{pid: pid} = state) do
    case :jamdb_oracle.stop(pid) do
      :ok -> :ok
      {:error, reason} -> {:error, reason, state}
    end
  end

  @doc false
  @spec reconnect(new_opts :: Keyword.t, state) :: {:ok, state}
  def reconnect(new_opts, state) do
    with :ok <- disconnect("Reconnecting", state),
      do: connect(new_opts)
  end

  @doc false
  @spec checkout(state) :: {:ok, state}
                         | {:disconnect, Exception.t, state}
  def checkout(state) do
    query = %Query{name: "session", statement: "SESSION"}
    case do_query(query, [], [], state) do
      {:ok, _, new_state} -> {:ok, new_state}
      error -> error
    end
  end

  @doc false
  @spec checkin(state) :: {:ok, state}
                        | {:disconnect, Exception.t, state}
  def checkin(state) do
    {:ok, state}
  end

  @doc false
  @spec handle_begin(opts :: Keyword.t, state) ::
    {:ok, result, state}
  | {:error | :disconnect, Exception.t, state}
  def handle_begin(opts, state) do
    case Keyword.get(opts, :mode, :transaction) do
      :transaction -> handle_transaction(:begin, opts, state)
      :savepoint -> handle_savepoint(:begin, opts, state)
    end
  end

  @doc false
  @spec handle_commit(opts :: Keyword.t, state) ::
    {:ok, result, state} |
    {:error | :disconnect, Exception.t, state}
  def handle_commit(opts, state) do
    case Keyword.get(opts, :mode, :transaction) do
      :transaction -> handle_transaction(:commit, opts, state)
      :savepoint -> handle_savepoint(:commit, opts, state)
    end
  end

  @doc false
  @spec handle_rollback(opts :: Keyword.t, state) ::
    {:ok, result, state} |
    {:error | :disconnect, Exception.t, state}
  def handle_rollback(opts, state) do
    case Keyword.get(opts, :mode, :transaction) do
      :transaction -> handle_transaction(:rollback, opts, state)
      :savepoint -> handle_savepoint(:rollback, opts, state)
    end
  end

  defp handle_transaction(:begin, _opts, state) do
    case state.ora do
      :idle -> {:ok, %Result{num_rows: 0}, %{state | ora: :transaction}}
      :transaction -> {:error,
      %Error{message: "Already in transaction"},
      state}
      :auto_commit -> {:error,
      %Error{message: "Transactions not allowed in autocommit mode"},
      state}
    end
  end
  defp handle_transaction(:commit, _opts, state) do
    query = %Query{name: "commit", statement: "COMMIT"}
    case do_query(query, [], [], state) do
      {:ok, _, new_state} -> {:ok, %Result{}, %{new_state | ora: :idle}}
      error -> error
    end
  end
  defp handle_transaction(:rollback, _opts, state) do
    query = %Query{name: "rollback", statement: "ROLLBACK"}
    case do_query(query, [], [], state) do
      {:ok, _, new_state} -> {:ok, %Result{}, %{new_state | ora: :idle}}
      error -> error
    end
  end

  defp handle_savepoint(:begin, opts, state) do
    if state.ora == :autocommit do
      {:error,
       %Error{message: "savepoint not allowed in autocommit mode"},
       state}
    else
      handle_execute(
        %Query{name: "", statement: "SAVEPOINT svpt"},
        [], opts, state)
    end
  end
  defp handle_savepoint(:commit, _opts, state) do
    {:ok, %Result{}, state}
  end
  defp handle_savepoint(:rollback, opts, state) do
    handle_execute(
      %Query{name: "", statement: "ROLLBACK TO svpt"},
      [], opts, state)
  end

  @doc false
  @spec handle_prepare(query, opts :: Keyword.t, state) ::
    {:ok, query, state} |
    {:error | :disconnect, Exception.t, state}
  def handle_prepare(query, _opts, state) do
    {:ok, query, state}
  end

  @doc false
  @spec handle_execute(query, params, opts :: Keyword.t, state) ::
    {:ok, result, state} |
    {:error | :disconnect, Exception.t, state}
  def handle_execute(query, params, opts, state) do
    returning = Keyword.get(opts, :returning, []) |> Enum.filter(& is_tuple(&1))
    new_params = Enum.concat(params, returning)
    {status, message, new_state} = do_query(query, new_params, opts, state)

    case new_state.ora do
      :idle ->
        with {:ok, _, post_commit_state} <- handle_commit(opts, new_state)
        do
          {status, message, post_commit_state}
        end
      :transaction -> {status, message, new_state}
      :auto_commit ->
        with {:ok, _, post_connect_state} <- handle_command("COMOFF", [], new_state)
        do
          {status, message, post_connect_state}
        end
    end
  end

  defp do_query(query, params, opts, state) do
    case :jamdb_oracle.sql_query(state.pid, {query.statement |> to_charlist, params}) do
      {:ok, [{_, columns, _, rows}]} ->
        {:ok, %Result{num_rows: length(rows), rows: rows, columns: columns}, state}
      {:ok, [{_, 0, rows}]} -> {:ok, %Result{num_rows: length(rows), rows: rows}, state}
      {:ok, [{_, code, msg}]} -> {:error, %Error{ora_code: code, message: msg}, state}
      {:ok, [{_, num_rows}]} -> {:ok, %Result{num_rows: num_rows, rows: nil}, state}
      {:ok, result} -> {:ok, result, state}
      {:error, _, err} -> {:error, err, state}
    end
  end

  defp handle_command(statement, params, state) do
    query = %Query{name: "", statement: statement}
    case do_query(query, params, [], state) do
      {:ok, _, new_state} -> {:ok, %Result{}, %{new_state | ora: :idle}}
      error -> error
    end
  end
  
  @doc false
  @spec handle_close(query, opts :: Keyword.t, state) ::
    {:ok, result, state} |
    {:error | :disconnect, Exception.t, state}
  def handle_close(_query, _opts, state) do
    {:ok, %Result{}, state}
  end

  @doc false
  def ping(state) do
    query = %Query{name: "ping", statement: "PING"}
    case do_query(query, [], [], state) do
      {:ok, _, new_state} -> {:ok, new_state}
      {:error, reason, new_state} -> {:disconnect, reason, new_state}
    end
  end

  # @spec handle_declare(query, params, opts :: Keyword.t, state) ::
  #   {:ok, cursor, state} |
  #   {:error | :disconnect, Exception.t, state}
  # def handle_declare(_query, _params, _opts, state) do
  #   {:error, "not implemented", state}
  # end
  #
  # @spec handle_first(query, cursor, opts :: Keyword.t, state) ::
  #   {:ok | :deallocate, result, state} |
  #   {:error | :disconnect, Exception.t, state}
  # def handle_first(_query, _cursor, _opts, state) do
  #   {:error, "not implemented", state}
  # end
  #
  # @spec handle_next(query, cursor, opts :: Keyword.t, state) ::
  #   {:ok | :deallocate, result, state} |
  #   {:error | :disconnect, Exception.t, state}
  # def handle_next(_query, _cursor, _opts, state) do
  #   {:error, "not implemented", state}
  # end
  #
  # @spec handle_deallocate(query, cursor, opts :: Keyword.t, state) ::
  #   {:ok, result, state} |
  #   {:error | :disconnect, Exception.t, state}
  # def handle_deallocate(_query, _cursor, _opts, state) do
  #   {:error, "not implemented", state}
  # end
  #
end
