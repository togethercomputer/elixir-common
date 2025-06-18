if Code.ensure_loaded?(Ecto.ParameterizedType) do
  defmodule Together.ID do
    @moduledoc """
    Ecto-compatible, prefixed, base-58 encoded UUIDv7 data type

    Taken in part from https://danschultzer.com/posts/prefixed-base58-uuidv7-object-ids-with-ecto.

    ## Examples

        @primary_key {:id, Together.ID, prefix: "acct", autogenerate: true}
        @foreign_key_type Together.ID

    """
    use Ecto.ParameterizedType

    @typedoc "Raw, minimal binary format of the UUID with no prefix data"
    @type uuid_binary :: <<_::128>>

    @typedoc "String format of the UUID with no prefix data"
    @type uuid_string :: Ecto.UUID.t()

    @typedoc "Encoded format of the UUID with prefix"
    @type uuid_slug :: String.t()

    @nil_id <<0::128>>

    #
    # Callbacks
    #

    @doc false
    @impl Ecto.ParameterizedType
    def init(opts) do
      if prefix = opts[:prefix] do
        %{prefix: prefix}
      else
        schema =
          opts[:schema] || raise "option `:schema` is required if `:prefix` is not provided"

        field = opts[:field] || raise "option `:field` is required if `:prefix` is not provided"

        %{schema: schema, field: field}
      end
    end

    @doc false
    @impl Ecto.ParameterizedType
    def type(_params), do: :uuid

    @doc false
    @impl Ecto.ParameterizedType
    def cast(nil, _params), do: {:ok, nil}

    def cast(uuid, params) do
      to_slug(uuid, prefix(params))
    end

    @doc false
    @impl Ecto.ParameterizedType
    def load(data, loader, params)
    def load(nil, _loader, _params), do: {:ok, nil}

    def load(data, _loader, params) do
      case Ecto.UUID.load(data) do
        {:ok, uuid_string} -> uuid_to_slug(uuid_string, prefix(params))
        :error -> :error
      end
    end

    @doc false
    @impl Ecto.ParameterizedType
    def dump(nil, _, _), do: {:ok, nil}
    def dump(uuid, _dumper, _params), do: to_binary(uuid)

    @doc false
    @impl Ecto.ParameterizedType
    def autogenerate(params) do
      case binary_to_slug(bingenerate(), prefix(params)) do
        {:ok, uuid_slug} -> uuid_slug
        :error -> raise "auto-generated invalid UUID"
      end
    end

    @doc false
    @impl Ecto.ParameterizedType
    def embed_as(_format, _params), do: :self

    @doc false
    @impl Ecto.ParameterizedType
    def equal?(a, b, params)
    def equal?(nil, nil, _), do: true

    def equal?(nil, uuid_slug, _params) do
      case to_binary(uuid_slug) do
        {:ok, uuid_binary} -> uuid_binary == @nil_id
        :error -> false
      end
    end

    def equal?(uuid_slug, nil, _params) do
      case to_binary(uuid_slug) do
        {:ok, uuid_binary} -> uuid_binary == @nil_id
        :error -> false
      end
    end

    def equal?(a, b, _params) do
      case {to_binary(a), to_binary(b)} do
        {{:ok, equal}, {:ok, equal}} -> true
        _else -> false
      end
    end

    @spec prefix(map) :: String.t()
    defp prefix(%{prefix: prefix}), do: prefix

    defp prefix(%{schema: schema, field: field}) do
      %{related: schema, related_key: field} = schema.__schema__(:association, field)

      case schema.__schema__(:type, field) do
        {:parameterized, {__MODULE__, %{prefix: prefix}}} -> prefix
        _else -> "prefix_not_set"
      end
    end

    #
    # Generator
    #

    @rfc_variant 2

    @doc false
    @spec bingenerate :: uuid_binary
    def bingenerate do
      time = System.system_time(:millisecond)
      <<rand_a::12, rand_b::62, _::6>> = :crypto.strong_rand_bytes(10)

      <<time::big-unsigned-integer-size(48), 7::4, rand_a::12, @rfc_variant::2, rand_b::62>>
    end

    #
    # Format Converters
    #

    @doc """
    Convert a UUID, regardless of current format, into its raw binary form

    ## Examples

        iex> Together.ID.to_binary(<<1, 147, 48, 97, 106, 163, 123, 39, 141, 46, 234, 126, 170, 90, 115, 70>>)
        {:ok, <<1, 147, 48, 97, 106, 163, 123, 39, 141, 46, 234, 126, 170, 90, 115, 70>>}

        iex> Together.ID.to_binary("01933061-6aa3-7b27-8d2e-ea7eaa5a7346")
        {:ok, <<1, 147, 48, 97, 106, 163, 123, 39, 141, 46, 234, 126, 170, 90, 115, 70>>}

        iex> Together.ID.to_binary("test_CHErKsMSgQVrdQxEj7nmB")
        {:ok, <<1, 147, 48, 97, 106, 163, 123, 39, 141, 46, 234, 126, 170, 90, 115, 70>>}

        iex> Together.ID.to_binary("bad data")
        :error

    """
    @spec to_binary(uuid_binary) :: {:ok, uuid_binary} | :error
    @spec to_binary(uuid_string) :: {:ok, uuid_binary} | :error
    @spec to_binary(uuid_slug) :: {:ok, uuid_binary} | :error
    def to_binary(uuid)
    def to_binary(<<_::128>> = uuid_binary), do: {:ok, uuid_binary}

    def to_binary(<<_::64, ?-, _::32, ?-, _::32, ?-, _::32, ?-, _::96>> = uuid_string) do
      uuid_to_binary(uuid_string)
    end

    def to_binary(uuid_slug) do
      with {:ok, _prefix, uuid_binary} <- slug_to_binary(uuid_slug) do
        {:ok, uuid_binary}
      end
    end

    @doc """
    Convert a UUID, regardless of current format, into its raw binary form

    Same as `to_binary/1` but raises if conversion fails.

    ## Examples

        iex> Together.ID.to_binary!(<<1, 147, 48, 97, 106, 163, 123, 39, 141, 46, 234, 126, 170, 90, 115, 70>>)
        <<1, 147, 48, 97, 106, 163, 123, 39, 141, 46, 234, 126, 170, 90, 115, 70>>

        iex> Together.ID.to_binary!("01933061-6aa3-7b27-8d2e-ea7eaa5a7346")
        <<1, 147, 48, 97, 106, 163, 123, 39, 141, 46, 234, 126, 170, 90, 115, 70>>

        iex> Together.ID.to_binary!("test_CHErKsMSgQVrdQxEj7nmB")
        <<1, 147, 48, 97, 106, 163, 123, 39, 141, 46, 234, 126, 170, 90, 115, 70>>

        iex> Together.ID.to_binary!("bad data")
        ** (ArgumentError) invalid UUID format

    """
    @spec to_binary!(uuid_binary) :: uuid_binary | no_return
    @spec to_binary!(uuid_string) :: uuid_binary | no_return
    @spec to_binary!(uuid_slug) :: uuid_binary | no_return
    def to_binary!(uuid) do
      case to_binary(uuid) do
        {:ok, uuid_binary} -> uuid_binary
        :error -> raise ArgumentError, "invalid UUID format"
      end
    end

    @doc """
    Convert a UUID, regardless of current format, to a standard string form

    ## Examples

        iex> Together.ID.to_uuid(<<1, 147, 48, 97, 106, 163, 123, 39, 141, 46, 234, 126, 170, 90, 115, 70>>)
        {:ok, "01933061-6aa3-7b27-8d2e-ea7eaa5a7346"}

        iex> Together.ID.to_uuid("01933061-6aa3-7b27-8d2e-ea7eaa5a7346")
        {:ok, "01933061-6aa3-7b27-8d2e-ea7eaa5a7346"}

        iex> Together.ID.to_uuid("test_CHErKsMSgQVrdQxEj7nmB")
        {:ok, "01933061-6aa3-7b27-8d2e-ea7eaa5a7346"}

        iex> Together.ID.to_uuid("bad data")
        :error

    """
    @spec to_uuid(uuid_binary) :: {:ok, uuid_string} | :error
    @spec to_uuid(uuid_string) :: {:ok, uuid_string} | :error
    @spec to_uuid(uuid_slug) :: {:ok, uuid_string} | :error
    def to_uuid(uuid)
    def to_uuid(<<_::128>> = uuid_binary), do: binary_to_uuid(uuid_binary)

    def to_uuid(<<_::64, ?-, _::32, ?-, _::32, ?-, _::32, ?-, _::96>> = uuid_string) do
      {:ok, uuid_string}
    end

    def to_uuid(uuid_slug) do
      with {:ok, _prefix, uuid_string} <- slug_to_uuid(uuid_slug) do
        {:ok, uuid_string}
      end
    end

    @doc """
    Convert a UUID, regardless of current format, to a standard string form

    Same as `to_uuid/1` but raises if conversion fails.

    ## Examples

        iex> Together.ID.to_uuid!(<<1, 147, 48, 97, 106, 163, 123, 39, 141, 46, 234, 126, 170, 90, 115, 70>>)
        "01933061-6aa3-7b27-8d2e-ea7eaa5a7346"

        iex> Together.ID.to_uuid!("01933061-6aa3-7b27-8d2e-ea7eaa5a7346")
        "01933061-6aa3-7b27-8d2e-ea7eaa5a7346"

        iex> Together.ID.to_uuid!("test_CHErKsMSgQVrdQxEj7nmB")
        "01933061-6aa3-7b27-8d2e-ea7eaa5a7346"

        iex> Together.ID.to_uuid!("bad data")
        ** (ArgumentError) invalid UUID format

    """
    @spec to_uuid!(uuid_binary) :: uuid_string | no_return
    @spec to_uuid!(uuid_string) :: uuid_string | no_return
    @spec to_uuid!(uuid_slug) :: uuid_string | no_return
    def to_uuid!(uuid) do
      case to_uuid(uuid) do
        {:ok, uuid_string} -> uuid_string
        :error -> raise ArgumentError, "invalid UUID format"
      end
    end

    @doc """
    Convert a UUID, regardless of current format, to a base-58 encoded slug without prefix

    ## Examples

        iex> Together.ID.to_slug(<<1, 147, 48, 97, 106, 163, 123, 39, 141, 46, 234, 126, 170, 90, 115, 70>>)
        {:ok, "CHErKsMSgQVrdQxEj7nmB"}

        iex> Together.ID.to_slug("01933061-6aa3-7b27-8d2e-ea7eaa5a7346")
        {:ok, "CHErKsMSgQVrdQxEj7nmB"}

        iex> Together.ID.to_slug("test_CHErKsMSgQVrdQxEj7nmB")
        {:ok, "test_CHErKsMSgQVrdQxEj7nmB"}

        iex> Together.ID.to_slug("bad data")
        :error

    """
    @spec to_slug(uuid_binary) :: {:ok, uuid_slug} | :error
    @spec to_slug(uuid_string) :: {:ok, uuid_slug} | :error
    @spec to_slug(uuid_slug) :: {:ok, uuid_slug} | :error
    def to_slug(uuid)
    def to_slug(<<_::128>> = uuid_binary), do: binary_to_slug(uuid_binary, "")

    def to_slug(<<_::64, ?-, _::32, ?-, _::32, ?-, _::32, ?-, _::96>> = uuid_string) do
      uuid_to_slug(uuid_string, "")
    end

    def to_slug(uuid_slug) do
      case slug_to_binary(uuid_slug) do
        {:ok, _prefix, _uuid_binary} -> {:ok, uuid_slug}
        _else -> :error
      end
    end

    @doc """
    Convert a UUID, regardless of current format, to a base-58 encoded slug without prefix

    Same as `to_slug/1` but raises if conversion fails.

    ## Examples

        iex> Together.ID.to_slug!(<<1, 147, 48, 97, 106, 163, 123, 39, 141, 46, 234, 126, 170, 90, 115, 70>>)
        "CHErKsMSgQVrdQxEj7nmB"

        iex> Together.ID.to_slug!("01933061-6aa3-7b27-8d2e-ea7eaa5a7346")
        "CHErKsMSgQVrdQxEj7nmB"

        iex> Together.ID.to_slug!("test_CHErKsMSgQVrdQxEj7nmB")
        "test_CHErKsMSgQVrdQxEj7nmB"

        iex> Together.ID.to_slug!("bad data")
        ** (ArgumentError) invalid UUID format

    """
    @spec to_slug!(uuid_binary) :: uuid_slug | no_return
    @spec to_slug!(uuid_string) :: uuid_slug | no_return
    @spec to_slug!(uuid_slug) :: uuid_slug | no_return
    def to_slug!(uuid) do
      case to_slug(uuid) do
        {:ok, uuid_slug} -> uuid_slug
        :error -> raise ArgumentError, "invalid UUID format"
      end
    end

    @doc """
    Convert a UUID, regardless of current format, to a base-58 encoded slug with prefix

    ## Examples

        iex> Together.ID.to_slug(<<1, 147, 48, 97, 106, 163, 123, 39, 141, 46, 234, 126, 170, 90, 115, 70>>, "test")
        {:ok, "test_CHErKsMSgQVrdQxEj7nmB"}

        iex> Together.ID.to_slug("01933061-6aa3-7b27-8d2e-ea7eaa5a7346", "test")
        {:ok, "test_CHErKsMSgQVrdQxEj7nmB"}

        iex> Together.ID.to_slug("test_CHErKsMSgQVrdQxEj7nmB", "test")
        {:ok, "test_CHErKsMSgQVrdQxEj7nmB"}

        iex> Together.ID.to_slug("bad data", "test")
        :error

    """
    @spec to_slug(uuid_binary, String.t()) :: {:ok, uuid_slug} | :error
    @spec to_slug(uuid_string, String.t()) :: {:ok, uuid_slug} | :error
    @spec to_slug(uuid_slug, String.t()) :: {:ok, uuid_slug} | :error
    def to_slug(uuid, prefix)
    def to_slug(<<_::128>> = uuid_binary, prefix), do: binary_to_slug(uuid_binary, prefix)

    def to_slug(<<_::64, ?-, _::32, ?-, _::32, ?-, _::32, ?-, _::96>> = uuid_string, prefix) do
      uuid_to_slug(uuid_string, prefix)
    end

    def to_slug(uuid_slug, prefix) do
      case slug_to_binary(uuid_slug) do
        {:ok, ^prefix, _uuid_binary} -> {:ok, uuid_slug}
        _else -> :error
      end
    end

    @doc """
    Convert a UUID, regardless of current format, to a base-58 encoded slug with prefix

    Same as `to_slug/2` but raises if conversion fails.

    ## Examples

        iex> Together.ID.to_slug!(<<1, 147, 48, 97, 106, 163, 123, 39, 141, 46, 234, 126, 170, 90, 115, 70>>, "test")
        "test_CHErKsMSgQVrdQxEj7nmB"

        iex> Together.ID.to_slug!("01933061-6aa3-7b27-8d2e-ea7eaa5a7346", "test")
        "test_CHErKsMSgQVrdQxEj7nmB"

        iex> Together.ID.to_slug!("test_CHErKsMSgQVrdQxEj7nmB", "test")
        "test_CHErKsMSgQVrdQxEj7nmB"

        iex> Together.ID.to_slug!("bad data", "test")
        ** (ArgumentError) invalid UUID format

    """
    @spec to_slug!(uuid_binary, String.t()) :: uuid_slug | no_return
    @spec to_slug!(uuid_string, String.t()) :: uuid_slug | no_return
    @spec to_slug!(uuid_slug, String.t()) :: uuid_slug | no_return
    def to_slug!(uuid, prefix) do
      case to_slug(uuid, prefix) do
        {:ok, uuid_slug} -> uuid_slug
        :error -> raise ArgumentError, "invalid UUID format"
      end
    end

    @spec binary_to_slug(uuid_binary, String.t()) :: {:ok, uuid_slug} | :error
    defp binary_to_slug(<<_::128>> = uuid_binary, ""), do: {:ok, encode_base58(uuid_binary)}

    defp binary_to_slug(<<_::128>> = uuid_binary, prefix) do
      {:ok, "#{prefix}_#{encode_base58(uuid_binary)}"}
    end

    defp binary_to_slug(_data, _prefix), do: :error

    @spec binary_to_uuid(uuid_binary) :: {:ok, uuid_string} | :error
    defp binary_to_uuid(<<_::128>> = uuid_binary) do
      Ecto.UUID.cast(uuid_binary)
    end

    @spec slug_to_binary(uuid_slug) :: {:ok, String.t(), uuid_binary} | :error
    defp slug_to_binary(uuid_slug) do
      with [prefix, encoded_uuid] <- String.split(uuid_slug, "_"),
           {:ok, <<_::128>> = uuid_binary} <- decode_base58(encoded_uuid) do
        {:ok, prefix, uuid_binary}
      else
        _ -> :error
      end
    end

    @spec slug_to_uuid(uuid_slug) :: {:ok, String.t(), uuid_string} | :error
    defp slug_to_uuid(uuid_slug) do
      with {:ok, prefix, uuid_binary} <- slug_to_binary(uuid_slug),
           {:ok, uuid_string} <- binary_to_uuid(uuid_binary) do
        {:ok, prefix, uuid_string}
      else
        _ -> :error
      end
    end

    @spec uuid_to_binary(uuid_string) :: {:ok, uuid_binary} | :error
    defp uuid_to_binary(uuid_string), do: Ecto.UUID.dump(uuid_string)

    @spec uuid_to_slug(uuid_string, String.t()) :: {:ok, uuid_slug} | :error
    defp uuid_to_slug(uuid_string, prefix) do
      with {:ok, uuid_binary} <- uuid_to_binary(uuid_string) do
        binary_to_slug(uuid_binary, prefix)
      end
    end

    #
    # Base-58 Encoder and Decoder
    #

    @base58_alphabet ~c"123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"

    @spec encode_base58(binary) :: String.t()
    defp encode_base58(<<0, rest::binary>>), do: "1" <> encode_base58(rest)
    defp encode_base58(""), do: ""
    defp encode_base58(binary), do: :binary.decode_unsigned(binary) |> encode_base58("")

    @spec encode_base58(non_neg_integer, String.t()) :: String.t()
    defp encode_base58(0, acc), do: acc

    defp encode_base58(n, acc) do
      encode_base58(div(n, 58), <<encode_base58_digit(rem(n, 58))::binary, acc::binary>>)
    end

    @compile {:inline, encode_base58_digit: 1}
    @spec encode_base58_digit(non_neg_integer) :: <<_::8>>
    for {digit, index} <- Enum.with_index(@base58_alphabet) do
      defp encode_base58_digit(unquote(index)), do: unquote(<<digit>>)
    end

    @spec decode_base58(String.t()) :: {:ok, binary} | :error
    defp decode_base58(""), do: {:ok, ""}
    defp decode_base58("\0"), do: {:ok, ""}

    defp decode_base58(binary) do
      {zeroes, binary} = handle_leading_zeroes(binary)
      {:ok, zeroes <> decode_base58(binary, 0)}
    rescue
      _ -> :error
    end

    @spec decode_base58(String.t(), non_neg_integer) :: binary
    defp decode_base58("", 0), do: ""
    defp decode_base58("", acc), do: :binary.encode_unsigned(acc)

    defp decode_base58(<<head, tail::binary>>, acc) do
      decode_base58(tail, acc * 58 + decode_base58_char(head))
    end

    @compile {:inline, decode_base58_char: 1}
    @spec decode_base58_char(byte) :: non_neg_integer
    for {digit, index} <- Enum.with_index(@base58_alphabet) do
      defp decode_base58_char(unquote(digit)), do: unquote(index)
    end

    @spec handle_leading_zeroes(String.t()) :: {binary, String.t()}
    defp handle_leading_zeroes(binary) do
      original_length = String.length(binary)
      binary = String.trim_leading(binary, <<List.first(@base58_alphabet)>>)
      new_length = String.length(binary)
      {String.duplicate(<<0>>, original_length - new_length), binary}
    end

    #
    # Helpers
    #

    @doc """
    Extract the timestamp embedded in the UUIDv7

    ## Examples

        iex> Together.ID.extract_timestamp("01933061-6aa3-7b27-8d2e-ea7eaa5a7346")
        {:ok, ~U[2024-11-15 15:11:50.947Z]}

        iex> Together.ID.extract_timestamp("test_CQGFY5NK2muwxrpHsNJ28")
        {:ok, ~U[2025-06-18 19:38:02.580Z]}

        iex> Together.ID.extract_timestamp("bad data")
        :error

    """
    @spec extract_timestamp(uuid_binary) :: {:ok, DateTime.t()} | :error
    def extract_timestamp(uuid) do
      with {:ok, <<timestamp::big-unsigned-integer-size(48), _rest::binary>>} <- to_binary(uuid),
           {:ok, datetime} <- DateTime.from_unix(timestamp, :millisecond) do
        {:ok, datetime}
      else
        _ -> :error
      end
    end

    @doc """
    Get minimum and maximum UUID values for a given creation date

    A fun side-effect of the UUIDv7 format is the ability to bound the range of IDs that could
    be generated within a particular timeframe. This function finds the minimum and maximum ID
    values that can be generated on a given UTC calendar date.

    The lower bound is inclusive, meaning it is possible (though extremely unlikely) to generate
    an ID with that value. The upper bound is exclusive, as it belongs to the next calendar date.

    ## Example

      iex> Together.ID.min_max(~D[2025-03-01])
      {"01954f00-b000-7000-8000-000000000000", "01955427-0c00-7000-8000-000000000000"}

    """
    @spec min_max(Date.t()) :: {lower_bound :: uuid_string, upper_bound :: uuid_string}
    def min_max(date) do
      [date, Date.add(date, 1)]
      |> Enum.map(&DateTime.new!(&1, ~T[00:00:00], "Etc/UTC"))
      |> Enum.map(&DateTime.to_unix(&1, :millisecond))
      |> Enum.map(&<<&1::big-unsigned-integer-size(48), 7::4, 0::12, @rfc_variant::2, 0::62>>)
      |> Enum.map(&Ecto.UUID.cast!/1)
      |> List.to_tuple()
    end
  end
end
