defmodule Together.IPTest do
  use ExUnit.Case, async: true

  alias Together.IP

  describe "cast/1" do
    test "casts a string, charlist, or IP address tuple" do
      assert IP.cast("127.0.0.1") == {:ok, {127, 0, 0, 1}}
      assert IP.cast(~c'127.0.0.1') == {:ok, {127, 0, 0, 1}}
      assert IP.cast({127, 0, 0, 1}) == {:ok, {127, 0, 0, 1}}
    end

    test "returns :error for invalid input" do
      assert IP.cast("invalid_ip") == :error
      assert IP.cast(123) == :error
      assert IP.cast([]) == :error
    end
  end

  describe "load/1" do
    test "parses a string into an IP address tuple" do
      assert IP.load("127.0.0.1") == {:ok, {127, 0, 0, 1}}
    end
  end

  describe "dump/1" do
    test "dumps a string, charlist, or IP address tuple" do
      assert IP.dump("127.0.0.1") == {:ok, "127.0.0.1"}
      assert IP.dump(~c'127.0.0.1') == {:ok, "127.0.0.1"}
      assert IP.dump({127, 0, 0, 1}) == {:ok, "127.0.0.1"}
    end

    test "returns :error for invalid IP address tuples" do
      assert IP.dump({256, 0, 0, 1}) == :error
      assert IP.dump("invalid_ip") == :error
    end
  end
end
