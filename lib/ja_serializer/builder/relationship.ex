defmodule JaSerializer.Builder.Relationship do
  alias JaSerializer.Builder.Link
  alias JaSerializer.Builder.ResourceIdentifier

  defstruct [:name, :links, :data, :meta]

  @moduledoc """
  Builds up relationship data based on passed in options.

    has_one :author,
      link: "/articles/:id/author",
      type: "people"

    has_one :author,
      link: :author_link

  """

  def build(%{serializer: serializer} = context) do
    Enum.map serializer.__relations, &(build(&1, context))
  end

  defp build({_type, name, _opts} = definition, context) do
    %__MODULE__{name: name}
    |> add_links(definition, context)
    |> add_data(definition, context)
  end

  defp add_links(relation, {_type, _name, opts}, context) do
    case opts[:link] do
      nil ->  relation
      path -> Map.put(relation, :link, Link.build(context, :related, path))
    end
  end

  defp add_data(relation, {_t, name, opts}, context) do
    opts
    |> type_from_opts
    |> case do
      nil  -> relation
      type ->
        Map.put(relation, :data, ResourceIdentifier.build(context, type, name))
    end
  end

  defp type_from_opts(opts) do
    case {opts[:type], opts[:include]} do
      {nil, nil}        -> nil
      {nil, serializer} -> apply(serializer, :__type_key, [])
      {type, _}         -> type
    end
  end
end
