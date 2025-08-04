defmodule Together.Test.AssertionsTest do
  use ExUnit.Case

  import Together.Test.Assertions

  describe "assert_equal/2" do
    test "asserts that two values are equal" do
      assert_equal(2, 2)

      assert_raise ExUnit.AssertionError, fn ->
        assert_equal(2, 3)
      end
    end

    test "allows chaining assertions" do
      2
      |> assert_equal(2)
      |> Kernel.+(1)
      |> assert_equal(3)
    end
  end

  describe "assert_match/2" do
    test "asserts that the first argument matches the given pattern" do
      assert_match(%{"key" => "value"}, %{"key" => _})

      assert_raise ExUnit.AssertionError, fn ->
        assert_match(%{"key" => "value"}, %{"key" => "other"})
      end
    end

    test "allows chaining assertions" do
      %{"key" => "value"}
      |> assert_match(%{"key" => _})
      |> Map.put("new_key", "new_value")
      |> assert_match(%{"new_key" => _})
    end

    test "allows pinning in patterns" do
      value = "value"

      assert_match(%{"key" => "value"}, %{"key" => ^value})

      assert_raise ExUnit.AssertionError, fn ->
        assert_match(%{"key" => "other"}, %{"key" => ^value})
      end
    end

    test "allows extracting values in patterns" do
      assert_match(%{"key" => "value"}, %{"key" => extracted_value})
      assert extracted_value == "value"
    end
  end

  describe "assert_recent/2" do
    test "asserts that a timestamp is recent" do
      assert_recent(DateTime.utc_now())

      assert_raise ExUnit.AssertionError, fn ->
        assert_recent(DateTime.add(DateTime.utc_now(), -20, :second), 10)
      end
    end
  end

  describe "assert_set_equal/2" do
    test "asserts that two sets are equal" do
      assert_set_equal([1, 2, 3], [2, 3, 1])
      assert_set_equal([1, 2, 3], [2, 3, 1, 1])

      assert_raise ExUnit.AssertionError, fn ->
        assert_set_equal([1, 2, 3], [1, 2])
      end

      assert_raise ExUnit.AssertionError, fn ->
        assert_set_equal([1, 2, 3], [1, 2, 4])
      end

      assert_raise ExUnit.AssertionError, fn ->
        assert_set_equal([1, 2, 3], [1, 2, 3, 4])
      end
    end
  end

  describe "assert_set_match/2" do
    test "asserts that the first set matches the given pattern" do
      assert_set_match([1, 2, 3], [2, 3, _])

      assert_raise ExUnit.AssertionError, fn ->
        assert_set_match([1, 2, 3], [1, 2])
      end

      assert_raise ExUnit.AssertionError, fn ->
        assert_set_match([1, 2, 3], [1, 2, 4])
      end

      assert_raise ExUnit.AssertionError, fn ->
        assert_set_match([1, 2, 3], [1, 2, 3, 4])
      end
    end

    test "allows pinning in patterns" do
      value = 1
      assert_set_match([1, 2, 3], [^value, 2, _])
    end
  end

  describe "assert_contains/2" do
    test "asserts that a collection contains an item" do
      assert_contains([1, 2, 3], 2)

      assert_raise ExUnit.AssertionError, fn ->
        assert_contains([1, 2, 3], 4)
      end
    end

    test "allows chaining assertions" do
      [1, 2]
      |> assert_contains(2)
      |> Enum.map(&(&1 * 2))
      |> assert_contains(4)
    end
  end

  describe "assert_contains_match/2" do
    test "asserts that a collection contains an item matching the pattern" do
      assert_contains_match([%{"key" => "value"}, %{"other_key" => "other"}], %{"key" => _})

      assert_raise ExUnit.AssertionError, fn ->
        assert_contains_match([%{"key" => "value"}], %{"key" => "other"})
      end
    end

    test "allows pinning in patterns" do
      value = "value"
      assert_contains_match([%{"key" => "value"}, %{"other_key" => "other"}], %{"key" => ^value})
    end

    test "allows chaining assertions" do
      [%{"key" => "value"}, %{"other_key" => "other"}]
      |> assert_contains_match(%{"key" => _})
      |> Enum.map(&Map.new(&1, fn {k, v} -> {String.upcase(k), v} end))
      |> assert_contains_match(%{"KEY" => _})
    end
  end
end
