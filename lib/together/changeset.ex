if Code.ensure_loaded?(Ecto.Changeset) do
  defmodule Together.Changeset do
    @moduledoc """
    A module that provides a function to put a default value into a changeset.
    """
    alias Ecto.Changeset

    @doc """
    Puts a default value for a field into a changeset if the field is not already set (`nil`)

    ## Examples

        iex> changeset = Ecto.Changeset.change({%{}, %{email: :string}}, %{})
        iex> Together.Changeset.put_default(changeset, :email, "example@example.com")
        %Ecto.Changeset{
          changes: %{email: "example@example.com"},
          errors: [],
          data: %{},
          types: %{email: :string},
          valid?: true
        }

    """
    @spec put_default(Changeset.t(), atom, term) :: Changeset.t()
    def put_default(changeset, field, default) do
      case Changeset.get_field(changeset, field) do
        nil -> Changeset.put_change(changeset, field, default)
        _value -> changeset
      end
    end

    @doc """
    Validates that at least one of the given fields is provided in the changeset

    ## Examples

        iex> types = %{email: :string, password: :string}
        iex> changeset = Ecto.Changeset.change({%{}, types}, %{email: nil, password: nil})
        iex> Together.Changeset.validate_at_least_one_of(changeset, [:email, :password])
        %Ecto.Changeset{
          changes: %{},
          errors: [
            email: {"At least one of email, password must be provided", []},
            password: {"At least one of email, password must be provided", []}
          ],
          data: %{},
          types: %{email: :string, password: :string},
          valid?: false
        }

    """
    @spec validate_at_least_one_of(Changeset.t(), [atom]) :: Changeset.t()
    def validate_at_least_one_of(changeset, []), do: changeset

    def validate_at_least_one_of(changeset, fields) do
      all_fields_missing? =
        Enum.all?(fields, fn field ->
          changeset
          |> Changeset.get_field(field)
          |> is_nil()
        end)

      if all_fields_missing? do
        message = "At least one of #{Enum.join(fields, ", ")} must be provided"

        for field <- Enum.reverse(fields), reduce: changeset do
          changeset -> Changeset.add_error(changeset, field, message)
        end
      else
        changeset
      end
    end

    @doc """
    Validate email address format in a changeset

    ## Examples

        iex> changeset = Ecto.Changeset.change({%{}, %{email: :string}}, %{email: nil})
        iex> Together.Changeset.validate_email_address(changeset, :email).valid?
        true

        iex> changeset = Ecto.Changeset.change({%{}, %{email: :string}}, %{email: "example@example.com"})
        iex> Together.Changeset.validate_email_address(changeset, :email).valid?
        true

        iex> changeset = Ecto.Changeset.change({%{}, %{email: :string}}, %{email: "example.com"})
        iex> Together.Changeset.validate_email_address(changeset, :email).valid?
        false

        iex> changeset = Ecto.Changeset.change({%{}, %{email: :string}}, %{email: "a@example.com."})
        iex> Together.Changeset.validate_email_address(changeset, :email).valid?
        false

    """
    @spec validate_email_address(Changeset.t(), atom()) :: Changeset.t()
    def validate_email_address(changeset, field) do
      Changeset.validate_format(
        changeset,
        field,
        # https://www.tempmail.us.com/en/elixir/implementing-w3c-compliant-email-validation-in-elixir
        ~r/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/,
        message: "is not a valid email address"
      )
    end

    @doc """
    Validate email domain format in a changeset

    ## Examples

        iex> changeset = Ecto.Changeset.change({%{}, %{email: :string}}, %{email: "example@example.com"})
        iex> Together.Changeset.validate_email_domain(changeset, :email).valid?
        false

        iex> changeset = Ecto.Changeset.change({%{}, %{email: :string}}, %{email: "example.com"})
        iex> Together.Changeset.validate_email_domain(changeset, :email).valid?
        true

        iex> changeset = Ecto.Changeset.change({%{}, %{email: :string}}, %{email: "example.com."})
        iex> Together.Changeset.validate_email_domain(changeset, :email).valid?
        false

    """
    @spec validate_email_domain(Changeset.t(), atom()) :: Changeset.t()
    def validate_email_domain(changeset, field) do
      changeset
      |> Changeset.validate_format(
        field,
        # https://www.tempmail.us.com/en/elixir/implementing-w3c-compliant-email-validation-in-elixir
        ~r/^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/,
        message: "is not a valid email domain"
      )
      |> validate_domain_structure(field)
    end

    @spec validate_domain_structure(Changeset.t(), atom()) :: Changeset.t()
    defp validate_domain_structure(changeset, field) do
      address = Changeset.get_field(changeset, field)

      cond do
        not is_binary(address) ->
          changeset

        String.contains?(address, "..") ->
          Changeset.add_error(changeset, field, "is not a valid email domain")

        String.starts_with?(address, ".") or String.ends_with?(address, ".") ->
          Changeset.add_error(changeset, field, "is not a valid email domain")

        :else ->
          changeset
      end
    end
  end
end
