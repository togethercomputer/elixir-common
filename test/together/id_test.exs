defmodule Together.IDTest do
  use ExUnit.Case, async: true
  doctest Together.ID

  alias Together.ID

  defmodule IDTestSchema do
    use Ecto.Schema

    @primary_key {:id, ID, prefix: "test", autogenerate: true}
    @foreign_key_type ID

    schema "test" do
      belongs_to(:test, IDTestSchema)
    end
  end

  @params ID.init(
            schema: IDTestSchema,
            field: :id,
            primary_key: true,
            autogenerate: true,
            prefix: "test"
          )
  @belongs_to_params ID.init(schema: IDTestSchema, field: :test, foreign_key: :test_id)
  @loader nil
  @dumper nil

  @test_prefixed_uuid "test_CHEpgy5ajbDmj2AWJfrqj"
  @test_uuid Ecto.UUID.dump!("0193304d-c5a7-7a0b-baf1-cd54aa52e6ce")
  @test_prefixed_uuid_with_leading_one "test_157qasrQWT933xyZbXtfCu"
  @test_uuid_with_leading_one Ecto.UUID.dump!("0093305e-153a-7894-91e2-abed37205a22")
  @test_prefixed_uuid_null "test_1111111111111111"
  @test_uuid_null Ecto.UUID.dump!("00000000-0000-0000-0000-000000000000")
  @test_prefixed_uuid_invalid_characters "test_" <> String.duplicate(".", 32)
  @test_uuid_invalid_characters String.duplicate(".", 22)
  @test_prefixed_uuid_invalid_format "test_" <> String.duplicate("x", 31)
  @test_uuid_invalid_format String.duplicate("x", 21)

  test "cast/2" do
    assert ID.cast(@test_prefixed_uuid, @params) == {:ok, @test_prefixed_uuid}

    assert ID.cast(@test_prefixed_uuid_with_leading_one, @params) ==
             {:ok, @test_prefixed_uuid_with_leading_one}

    assert ID.cast(@test_prefixed_uuid_null, @params) == {:ok, @test_prefixed_uuid_null}
    assert ID.cast(nil, @params) == {:ok, nil}
    assert ID.cast("other-prefix" <> @test_prefixed_uuid, @params) == :error
    assert ID.cast(@test_prefixed_uuid_invalid_characters, @params) == :error
    assert ID.cast(@test_prefixed_uuid_invalid_format, @params) == :error
    assert ID.cast(@test_prefixed_uuid, @belongs_to_params) == {:ok, @test_prefixed_uuid}
  end

  test "load/3" do
    assert ID.load(@test_uuid, @loader, @params) == {:ok, @test_prefixed_uuid}

    assert ID.load(@test_uuid_with_leading_one, @loader, @params) ==
             {:ok, @test_prefixed_uuid_with_leading_one}

    assert ID.load(@test_uuid_null, @loader, @params) == {:ok, @test_prefixed_uuid_null}
    assert ID.load(@test_uuid_invalid_characters, @loader, @params) == :error
    assert ID.load(@test_uuid_invalid_format, @loader, @params) == :error
    assert ID.load(@test_prefixed_uuid, @loader, @params) == :error
    assert ID.load(nil, @loader, @params) == {:ok, nil}
    assert ID.load(@test_uuid, @loader, @belongs_to_params) == {:ok, @test_prefixed_uuid}
  end

  test "dump/3" do
    assert ID.dump(@test_prefixed_uuid, @dumper, @params) == {:ok, @test_uuid}

    assert ID.dump(@test_prefixed_uuid_with_leading_one, @dumper, @params) ==
             {:ok, @test_uuid_with_leading_one}

    assert ID.dump(@test_prefixed_uuid_null, @dumper, @params) == {:ok, @test_uuid_null}
    assert ID.dump(@test_uuid, @dumper, @params) == {:ok, @test_uuid}
    assert ID.dump(nil, @dumper, @params) == {:ok, nil}
    assert ID.dump(@test_prefixed_uuid, @dumper, @belongs_to_params) == {:ok, @test_uuid}
  end

  test "autogenerate/1" do
    assert "test_" <> _rest = uuid_slug = ID.autogenerate(@params)
    assert {:ok, <<_::128>> = uuid_binary} = ID.dump(uuid_slug, nil, @params)

    assert {:ok, <<_::64, ?-, _::32, ?-, ?7::8, _::24, ?-, _::32, ?-, _::96>>} =
             Ecto.UUID.load(uuid_binary)
  end
end
