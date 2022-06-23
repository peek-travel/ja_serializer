defmodule JaSerializer.EctoErrorSerializerTest do
  use ExUnit.Case

  alias JaSerializer.EctoErrorSerializer

  test "Will correctly ignore options from error message when they are not formattable" do
    expected = %{
      "errors" => [
        %{
          detail: "Title is invalid for reason: %{reason}",
          source: %{pointer: "/data/attributes/title"},
          title: "is invalid for reason: %{reason}"
        }
      ],
      "jsonapi" => %{"version" => "1.0"}
    }

    changeset =
      {%{}, %{title: :string}}
      |> Ecto.Changeset.cast(%{}, [])
      |> Ecto.Changeset.add_error(:title, "is invalid for reason: %{reason}", reason: {})

    assert expected == EctoErrorSerializer.format(changeset)
  end

  test "Will correctly format a changeset with an error" do
    expected = %{
      "errors" => [
        %{
          source: %{pointer: "/data/attributes/title"},
          title: "is invalid",
          detail: "Title is invalid"
        }
      ],
      "jsonapi" => %{"version" => "1.0"}
    }

    assert expected == EctoErrorSerializer.format(
      Ecto.Changeset.add_error(
        Ecto.Changeset.cast({%{}, %{title: :string}}, %{}, []),
        :title,
        "is invalid"
      )
    )
  end

  test "Will correctly format a changeset with a count error" do
    expected = %{
      "errors" => [
        %{
          source: %{pointer: "/data/attributes/monies"},
          title: "must be more than 10",
          detail: "Monies must be more than 10"
        }
      ],
      "jsonapi" => %{"version" => "1.0"}
    }

    assert expected == EctoErrorSerializer.format(
      Ecto.Changeset.add_error(
        Ecto.Changeset.cast({%{}, %{monies: :integer}}, %{}, []),
        :monies,
        "must be more than %{count}",
        [count: 10]
      )
    )
  end

  test "Will correctly format a changeset with multiple errors on one attribute" do
    expected = %{
      "errors" => [
        %{
          source: %{pointer: "/data/attributes/title"},
          title: "shouldn't be blank",
          detail: "Title shouldn't be blank"
        },
        %{
          source: %{pointer: "/data/attributes/title"},
          title: "is invalid",
          detail: "Title is invalid"
        }
      ],
      "jsonapi" => %{"version" => "1.0"}
    }

    changeset =
      {%{}, %{title: :string}}
      |> Ecto.Changeset.cast(%{}, [])
      |> Ecto.Changeset.add_error(:title, "is invalid")
      |> Ecto.Changeset.add_error(:title, "shouldn't be blank")

    assert expected == EctoErrorSerializer.format(changeset)
  end

  test "Support additional fields per the JSONAPI standard" do
    expected = %{
      "errors" => [
        %{
          id: "1",
          status: "422",
          code: "1000",
          title: "is invalid",
          detail: "Title is invalid",
          source: %{pointer: "/data/attributes/title"},
          links: %{self: "http://localhost"},
          meta: %{author: "Johnny"}
        }
      ],
      "jsonapi" => %{"version" => "1.0"}
    }

    assert expected == EctoErrorSerializer.format(
      Ecto.Changeset.add_error(
        Ecto.Changeset.cast({%{}, %{title: :string}}, %{}, []),
        :title,
        "is invalid"
      ),
      opts: [id: "1", status: "422", code: "1000", links: %{self: "http://localhost"}, meta: %{author: "Johnny"}]
    )
  end

  test "Ignores extra keys in errors" do
    expected = %{
      "errors" => [
        %{
          source: %{pointer: "/data/attributes/title"},
          title: "is invalid",
          detail: "Title is invalid"
        }
      ],
      "jsonapi" => %{"version" => "1.0"}
    }

    assert expected == EctoErrorSerializer.format(
      Ecto.Changeset.add_error(
        Ecto.Changeset.cast({%{}, %{title: :string}}, %{}, []),
        :title,
        "is invalid",
        extra: "info"
      )
    )
  end
end
