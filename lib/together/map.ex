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

      # a bit weird, but the point is showing that if values are duplicated one of the keys "survives",
      # while the other is dropped, whether :a or :b "survive" is non deterministic.
      iex> result = invert(%{a: 1, b: 1})
      iex> Map.keys(result)
      [1]
      iex> result[1] in [:a, :b]
      true

      iex> invert(%{})
      %{}
  """
  @spec invert(map) :: map()
  def invert(map) do
    Map.new(map, fn {key, value} -> {value, key} end)
  end
end
