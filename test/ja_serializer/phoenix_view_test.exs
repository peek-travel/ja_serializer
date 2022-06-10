defmodule JaSerializer.PhoenixViewTest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  defmodule PhoenixExample.ArticleView do
    use JaSerializer.PhoenixView
    attributes([:title])
    location("/api/articles")
  end

  @view PhoenixExample.ArticleView

  setup do
    m1 = %TestModel.Article{id: 1, title: "article one"}
    m2 = %TestModel.Article{id: 2, title: "article two"}
    {:ok, m1: m1, m2: m2}
  end

  defmodule Page do
    defstruct page_number: 3, total_pages: 5, page_size: 10
  end

  test "render conn, index.json-api, data: data", c do
    json = @view.render("index.json-api", conn: %{}, data: [c[:m1], c[:m2]])
    assert [a1, _a2] = json["data"]
    assert Map.has_key?(a1, "id")
    assert Map.has_key?(a1, "attributes")
  end

  # This should be deprecated in the future
  test "render conn, index.json, data: data", c do
    error_output =
      capture_io(:stderr, fn ->
        json = @view.render("index.json", conn: %{}, data: [c[:m1], c[:m2]])
        assert [a1, _a2] = json["data"]
        assert Map.has_key?(a1, "id")
        assert Map.has_key?(a1, "attributes")
      end)

    assert error_output =~
             "warning: Please use index.json-api instead. This will stop working in a future version."
  end

  test "render conn, index.json-api, articles: models", c do
    error_output =
      capture_io(:stderr, fn ->
        json =
          @view.render("index.json-api", conn: %{}, articles: [c[:m1], c[:m2]])

        assert [a1, _a2] = json["data"]
        assert Map.has_key?(a1, "id")
        assert Map.has_key?(a1, "attributes")
      end)

    assert error_output =~
             "Passing data via `:model`, `:articles` or `:article`"
  end

  test "render conn, index.json-api, model: model with custom pagination", c do
    json =
      @view.render(
        "index.json-api",
        conn: %{},
        data: [c[:m1], c[:m2]],
        opts: [page: [first: "/v1/posts/foo"]]
      )

    assert [a1, _a2] = json["data"]
    assert Map.has_key?(a1, "id")
    assert Map.has_key?(a1, "attributes")
    assert Map.has_key?(json, "links")
  end

  test "render conn, index.json-api, model: model with custom pagination using urls with ports",
       c do
    json =
      @view.render(
        "index.json-api",
        conn: %{},
        data: [c[:m1], c[:m2]],
        opts: [page: [first: "http://localhost:4000/v1/posts/foo"]]
      )

    assert [a1, _a2] = json["data"]
    assert Map.has_key?(a1, "id")
    assert Map.has_key?(a1, "attributes")
    assert Map.has_key?(json, "links")
  end

  test "render conn, index.json-api, model: model with scrivener pagination",
       c do
    model = %Scrivener.Page{entries: [c[:m1], c[:m2]], page_number: 1}
    conn = %Plug.Conn{query_params: %{}}
    json = @view.render("index.json-api", conn: conn, data: model)
    assert [a1, _a2] = json["data"]
    assert Map.has_key?(a1, "id")
    assert Map.has_key?(a1, "attributes")
    assert Map.has_key?(json, "links")
  end

  test "render conn, index.json-api, model: model with scrivener pagination and overriding base url",
       c do
    model = %Scrivener.Page{entries: [c[:m1], c[:m2]], page_number: 1}
    conn = %Plug.Conn{query_params: %{}}

    json =
      @view.render("index.json-api",
        conn: conn,
        data: model,
        opts: [base_url: "http://base-url.com"]
      )

    assert [a1, _a2] = json["data"]
    assert Map.has_key?(a1, "id")
    assert Map.has_key?(a1, "attributes")

    assert json["links"] == %{
             "last" => "http://base-url.com?page[number]=&page[size]=",
             "next" => "http://base-url.com?page[number]=2&page[size]=",
             "self" => "http://base-url.com?page[number]=1&page[size]="
           }
  end

  test "render conn, show.json-api, data: model", c do
    json = @view.render("show.json-api", conn: %{}, data: c[:m1])
    assert Map.has_key?(json["data"], "id")
    assert Map.has_key?(json["data"], "attributes")
  end

  test "render conn, show.json-api, data: nil" do
    json = @view.render("show.json-api", conn: %{}, data: nil)
    assert json['data'] == nil
  end

  # This should be deprecated in the future
  test "render conn, show.json, data: model", c do
    error_output =
      capture_io(:stderr, fn ->
        json = @view.render("show.json", conn: %{}, data: c[:m1])
        assert Map.has_key?(json["data"], "id")
        assert Map.has_key?(json["data"], "attributes")
      end)

    assert error_output =~
             "warning: Please use show.json-api instead. This will stop working in a future version.\n"
  end

  test "render conn, show.json-api, article: model", c do
    error_output =
      capture_io(:stderr, fn ->
        json = @view.render("show.json-api", conn: %{}, article: c[:m1])
        assert Map.has_key?(json["data"], "id")
        assert Map.has_key?(json["data"], "attributes")
      end)

    assert error_output =~
             "Passing data via `:model`, `:articles` or `:article`"
  end

  test "render conn, 'errors.json-api', data: changeset" do
    errors = Ecto.Changeset.add_error(%Ecto.Changeset{}, :title, "is invalid")
    json = @view.render("errors.json-api", conn: %{}, data: errors)
    assert Map.has_key?(json, "errors")
    assert [e1] = json["errors"]
    assert e1.source.pointer == "/data/attributes/title"
    assert e1.detail == "Title is invalid"
  end

  # This should be deprecated in the future
  test "render conn, 'errors.json', data: changeset" do
    error_output =
      capture_io(:stderr, fn ->
        errors =
          Ecto.Changeset.add_error(%Ecto.Changeset{}, :title, "is invalid")

        json = @view.render("errors.json", conn: %{}, data: errors)
        assert Map.has_key?(json, "errors")
      end)

    assert error_output =~
             "warning: Please use errors.json-api instead. This will stop working in a future version.\n"
  end

  describe "with nested changesets" do
    test "render conn, 'errors.json-api', data: changeset" do
      errors =
        {%{}, %{title: :string}}
        |> Ecto.Changeset.cast(%{}, [])
        |> Ecto.Changeset.add_error(:title, "is invalid")

      json = @view.render("errors.json-api", conn: %{}, data: errors)
      assert Map.has_key?(json, "errors")
      assert [e1] = json["errors"]
      assert e1.source.pointer == "/data/attributes/title"
      assert e1.detail == "Title is invalid"
    end

    # This should be deprecated in the future
    test "render conn, 'errors.json', data: changeset" do
      error_output =
        capture_io(:stderr, fn ->
          errors =
            {%{}, %{title: :string}}
            |> Ecto.Changeset.cast(%{}, [])
            |> Ecto.Changeset.add_error(:title, "is invalid")

          json = @view.render("errors.json", conn: %{}, data: errors)
          assert Map.has_key?(json, "errors")
        end)

      assert error_output =~
               "warning: Please use errors.json-api instead. This will stop working in a future version.\n"
    end
  end
end
