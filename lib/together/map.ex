defmodule Together.Map do
  @moduledoc """
  Helper functions for dealing with maps.

  Would be great to have them in elixir core, but for now they aren't wanted.
  """

  @doc """
  Inverts a map, exchanging keys and values.

  ## Examples

      iex> invert(%{a: 1, b: 2})
      %{1 => :a, 2 => :b}

      # this one depends a bit on ordering of the map inside the BEAM, but wanted to show that
      # no values get aggregated.
      iex> invert(%{a: 1, b: 1})
      %{1 => :b}

      iex> invert(%{})
      %{}
  """
  @spec invert(map) :: map()
  def invert(map) do
    Map.new(map, fn {key, value} -> {value, key} end)
  end
end
