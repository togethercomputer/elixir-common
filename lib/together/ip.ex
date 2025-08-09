defmodule Together.IP do
  @moduledoc """
  Ecto-compatible type for storing IP addresses

  Migrations should use the `:inet` type for the database column.

  ## Example

      # Schema
      schema "example" do
        field :ip_address, Together.IP
      end

      # Migration
      def change do
        create table(:example) do
          add :ip_address, :inet
        end
      end

  """
  if Code.ensure_loaded?(Ecto.Type) do
    @behaviour Ecto.Type

    @doc false
    @impl Ecto.Type
    def type, do: :string

    @doc false
    @impl Ecto.Type
    def cast(value) when is_binary(value) or is_list(value), do: parse_address(value)
    def cast({_, _, _, _} = value), do: {:ok, value}
    def cast(_invalid), do: :error

    @doc false
    @impl Ecto.Type
    def load(value), do: parse_address(value)

    @doc false
    @impl Ecto.Type
    def dump(value) when is_binary(value) or is_list(value) do
      with {:ok, ip_address} <- parse_address(value) do
        dump(ip_address)
      end
    end

    def dump({_, _, _, _} = value) do
      case :inet.ntoa(value) do
        {:error, :einval} -> :error
        ip_address_charlist -> {:ok, to_string(ip_address_charlist)}
      end
    end

    def dump(_), do: :error

    @doc false
    @impl Ecto.Type
    def equal?(value1, value2) do
      value1 == value2
    end

    @doc false
    @impl Ecto.Type
    def embed_as(_), do: :self

    @spec parse_address(String.t() | charlist) :: {:ok, :inet.ip_address()} | :error
    defp parse_address(ip_address_string_or_charlist) do
      ip_address_charlist = to_charlist(ip_address_string_or_charlist)

      case :inet.parse_address(ip_address_charlist) do
        {:ok, ip_address} -> {:ok, ip_address}
        {:error, :einval} -> :error
      end
    end
  end
end
