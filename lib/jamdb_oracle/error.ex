defmodule Jamdb.Oracle.Error do
  @moduledoc """
  Defines an error returned from the driver.
  """

  defexception [:message, :code]

  @type t :: %__MODULE__{
    message: binary(),
    code: integer()
  }

  @doc false
  @spec exception(binary()) :: t()
  def exception({code, reason} = message) do
    %__MODULE__{
      message: to_string(reason),
      code: code
    }
  end

  def exception(message) do
    %__MODULE__{
      message: to_string(message)
    }
  end
end
