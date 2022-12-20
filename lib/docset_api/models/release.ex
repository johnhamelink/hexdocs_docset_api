defmodule DocsetApi.Release do
  defstruct name: nil,
            version: 0,
            url: nil,
            docs_url: nil,
            docs_html_url: nil,
            has_docs: nil,
            destination: nil,
            inserted_at: nil,
            updated_at: nil
end
