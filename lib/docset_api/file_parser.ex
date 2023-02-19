defmodule DocsetApi.FileParser do
  require Logger

  @spec parse_zeal_navigation(Floki.html_tree(), binary(), fun()) :: Floki.html_tree()
  def parse_zeal_navigation(html, relative_path, callback) when is_function(callback) do
    module = parse_module(html)

    if module != "" do
      callback.(module, "Module", "#{relative_path}#content")

      for function <- parse_functions(html) do
        callback.("#{module}.#{function}", "Function", "#{relative_path}##{function}")
      end

      for macro <- parse_macros(html) do
        callback.("#{module}.#{macro}", "Macro", "#{relative_path}##{macro}")
      end

      for "c:" <> callback_id <- parse_callbacks(html) do
        callback.("#{module}.#{callback_id}", "Callback", "#{relative_path}#c:#{callback_id}")
      end

      for "t:" <> type <- parse_types(html) do
        callback.("#{module}.#{type}", "Type", "#{relative_path}#t:#{type}")
      end
    end

    html
  end

  defp parse_module(html) do
    html
    |> Floki.find("#content>h1>span")
    |> Floki.text()
  end

  defp parse_functions(html) do
    html
    |> Floki.find("#functions .detail")
    |> Floki.attribute("id")
  end

  defp parse_macros(html) do
    html
    |> Floki.find("#macros .detail")
    |> Floki.attribute("id")
  end

  defp parse_callbacks(html) do
    html
    |> Floki.find(".detail")
    |> Floki.attribute("id")
    |> Enum.filter(&String.starts_with?(&1, "c:"))
  end

  defp parse_types(html) do
    html
    |> Floki.find(".detail")
    |> Floki.attribute("id")
    |> Enum.filter(&String.starts_with?(&1, "t:"))
  end
end
