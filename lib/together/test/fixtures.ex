defmodule Together.Test.Fixtures do
  @moduledoc """
  Helpers for reading and using JSON test fixtures

  This module provides functions to read JSON fixtures from the `fixture` directory, decode them,
  and randomize any IDs present to avoid database deadlocks in async tests. Randomized IDs are
  consistent within the same test process, even across multiple fixture files.

  Randomization is done with the following rules:

    * The key must be named `id`, end with `_id`, or be specified in the `:keys` option.
    * Values that are `null` are left unchanged.
    * Numeric IDs are replaced with a unique positive integer using `System.unique_integer/1`.
    * UUIDs are replaced with a new UUID using `Ecto.UUID.generate/0`.
    * Other values are replaced with a string prefixed with `gen_` and a new UUID.

  ## Configuration

  To reduce boilerplate, you can set the base path for fixtures in your `config/config.exs`:

      config :together, fixture_path: "test/fixtures"

  ## Example

      defmodule MyApp.Test.MyTest do
        use ExUnit.Case, async: true
        alias Together.Test.Fixtures

        test "example test" do
          fixture = Fixtures.load("my_fixture.json")
          # ...
        end
      end
  """

  @id_map_dictionary_key :tg_test_fixture_id_map
  @uuid_re ~r/[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}/

  @doc """
  Read and decode a JSON fixture from the given path, then randomize any IDs present

  Matching IDs within the same file will continue to match with different values. Doing this helps
  to prevent database deadlocks that can occur when async tests use fixtures with the same IDs.

  ## Options

    * `keys`: List of additional keys to randomize. By default, only keys named `id` and those
      ending with `_id` will be randomized.

  """
  @spec load(String.t(), keyword) :: any
  def load(path, opts \\ []) do
    base_path = Application.get_env(:together, :fixture_path, "")

    Path.join(base_path, path)
    |> File.read!()
    |> JSON.decode!()
    |> randomize(opts[:keys] || [])
  end

  @doc false
  @spec randomize(any, [String.t()]) :: any
  def randomize(value, extra_keys) do
    id_map = Process.get(@id_map_dictionary_key, %{})
    {id_map, value} = randomize(id_map, value, extra_keys)
    Process.put(@id_map_dictionary_key, id_map)

    value
  end

  @spec randomize(map, any, [String.t()]) :: {map, any}
  defp randomize(id_map, map_value, extra_keys) when is_map(map_value) do
    Enum.reduce(map_value, {id_map, %{}}, fn
      {key, value}, {id_map, modified_map} ->
        if key == "id" or String.ends_with?(key, "_id") or key in extra_keys do
          cond do
            is_nil(value) ->
              {id_map, modified_map}

            is_integer(value) ->
              new_id = Map.get_lazy(id_map, value, fn -> System.unique_integer([:positive]) end)
              {Map.put(id_map, value, new_id), Map.put(modified_map, key, new_id)}

            is_binary(value) ->
              case Regex.scan(@uuid_re, value) do
                [] ->
                  new_id = Map.get_lazy(id_map, value, fn -> "gen_" <> Ecto.UUID.generate() end)
                  {Map.put(id_map, value, new_id), Map.put(modified_map, key, new_id)}

                matches ->
                  {id_map, modified_value} =
                    Enum.reduce(matches, {id_map, value}, fn [match], {id_map, modified_value} ->
                      new_id = Map.get_lazy(id_map, match, fn -> Ecto.UUID.generate() end)

                      {Map.put(id_map, match, new_id),
                       String.replace(modified_value, match, new_id)}
                    end)

                  {id_map, Map.put(modified_map, key, modified_value)}
              end

            :else ->
              {id_map, modified_map}
          end
        else
          {id_map, modified_value} = randomize(id_map, value, extra_keys)
          {id_map, Map.put(modified_map, key, modified_value)}
        end
    end)
  end

  defp randomize(id_map, list_value, extra_keys) when is_list(list_value) do
    {id_map, list_value} =
      Enum.reduce(list_value, {id_map, []}, fn list_element, {id_map, modified_list} ->
        {id_map, modified_list_element} = randomize(id_map, list_element, extra_keys)
        {id_map, [modified_list_element | modified_list]}
      end)

    {id_map, Enum.reverse(list_value)}
  end

  defp randomize(id_map, value, _extra_keys), do: {id_map, value}
end
