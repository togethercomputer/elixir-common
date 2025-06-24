defmodule Together.Test.FixturesTest do
  use ExUnit.Case, async: true

  alias Together.Test.Fixtures

  @uuid_re ~r/[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}/

  describe "load/2" do
    test "loads and randomizes a fixture" do
      output = Fixtures.load("test/fixture/example.json", keys: ["custom"])

      assert output["id"] != 12345
      assert is_integer(output["id"])
      assert output["id"] > 0

      assert output["other"] == "data"

      assert output["nested"]["related_id"] != "f91dea2c-14e4-4ac2-a09a-f451b14e1f36"
      assert output["nested"]["related_id"] =~ @uuid_re

      assert output["related"]["id"] != "f91dea2c-14e4-4ac2-a09a-f451b14e1f36"
      assert output["related"]["id"] =~ @uuid_re
      assert output["related"]["id"] == output["nested"]["related_id"]

      assert output["stytch_style_id"] != "organization-test-1917c469-dc9e-487d-a019-b15e36cb5cae"

      assert output["stytch_style_id"] =~
               ~r/organization-test-[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}/

      assert is_nil(output["null_id"])

      assert output["custom"] != 12345
      assert is_integer(output["custom"])
      assert output["custom"] > 0
    end
  end

  describe "randomize/2" do
    test "randomizes integer IDs" do
      input = %{
        "id" => 12345,
        "another_id" => 67890
      }

      output = Fixtures.randomize(input, [])

      assert output["id"] != 12345
      assert is_integer(output["id"])
      assert output["id"] > 0

      assert output["another_id"] != 67890
      assert is_integer(output["another_id"])
      assert output["another_id"] > 0
    end

    test "randomizes UUIDs" do
      input = %{
        "id" => "1d6f6021-150e-4839-8e06-edf50fac387b",
        "another_id" => "93ddb2fa-b3af-46dc-abbc-a5d5990819e6"
      }

      output = Fixtures.randomize(input, [])

      assert output["id"] != "1d6f6021-150e-4839-8e06-edf50fac387b"
      assert output["id"] =~ @uuid_re

      assert output["another_id"] != "93ddb2fa-b3af-46dc-abbc-a5d5990819e6"
      assert output["another_id"] =~ @uuid_re
    end

    test "randomizes UUID substrings" do
      input = %{
        "custom_id" =>
          "multiple-7d85dc07-0d75-4f5c-b9dd-4f7a7a6612c7-ids-93ddb2fa-b3af-46dc-abbc-a5d5990819e6",
        "another_id" => "93ddb2fa-b3af-46dc-abbc-a5d5990819e6"
      }

      output = Fixtures.randomize(input, [])

      assert output["another_id"] != "93ddb2fa-b3af-46dc-abbc-a5d5990819e6"
      assert output["another_id"] =~ @uuid_re

      refute String.contains?(output["custom_id"], "7d85dc07-0d75-4f5c-b9dd-4f7a7a6612c7")
      refute String.contains?(output["custom_id"], "93ddb2fa-b3af-46dc-abbc-a5d5990819e6")

      assert output["custom_id"] =~
               ~r/multiple-[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}-ids-[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}/

      assert String.ends_with?(output["custom_id"], output["another_id"])
    end

    test "mirrors matching IDs in the same file" do
      input = %{
        "id" => 12345,
        "mirror_id" => 12345,
        "my_id" => "1d6f6021-150e-4839-8e06-edf50fac387b",
        "mirror_my_id" => "1d6f6021-150e-4839-8e06-edf50fac387b"
      }

      output = Fixtures.randomize(input, [])

      assert output["id"] != 12345
      assert output["mirror_id"] == output["id"]

      assert output["my_id"] != "1d6f6021-150e-4839-8e06-edf50fac387b"
      assert output["mirror_my_id"] == output["my_id"]
    end

    test "mirrors matching IDs across files" do
      input1 = %{
        "id" => 12345,
        "mirror_id" => 67890
      }

      input2 = %{
        "id" => 67890,
        "mirror_id" => 12345
      }

      output1 = Fixtures.randomize(input1, [])
      output2 = Fixtures.randomize(input2, [])

      assert output2["mirror_id"] == output1["id"]
      assert output1["mirror_id"] == output2["id"]
    end

    test "does not modify non-ID keys" do
      input = %{
        "id" => 12345,
        "name" => "Test",
        "description" => "This is a test"
      }

      output = Fixtures.randomize(input, [])

      assert output["name"] == "Test"
      assert output["description"] == "This is a test"
    end
  end
end
