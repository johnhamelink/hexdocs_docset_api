defmodule DocsetApi.Release do
  use DocsetApi.Web, :model

  schema "releases" do
    field :name, :string
    field :version, :string
    field :url, :string
    field :docs_url, :string
    field :has_docs, :boolean
    timestamps
  end

end
