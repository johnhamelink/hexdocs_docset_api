defmodule DocsetApi.FileParser do
  require Logger

  @spec parse_zeal_navigation(Floki.html_tree(), binary(), fun()) :: Floki.html_tree()
  def parse_zeal_navigation(html_tree, relative_path, callback) when is_function(callback) do
    module = parse_module(html_tree)

    body_classes =
      Floki.attribute(html_tree, "body", "class")
      |> Enum.join(" ")

    is_guide =
      String.contains?(body_classes, "page-extra") or
        String.contains?(body_classes, "page-cheatmd")

    is_exception = String.contains?(body_classes, "page-exception")
    is_protocol = String.contains?(body_classes, "page-protocol")

    cond do
      module != "" and not is_guide and not is_exception and not is_protocol ->
        callback.(module, "Module", "#{relative_path}#content")

        for function <- parse_functions(html_tree) do
          callback.("#{module}.#{function}", "Function", "#{relative_path}##{function}")
        end

        for macro <- parse_macros(html_tree) do
          callback.("#{module}.#{macro}", "Macro", "#{relative_path}##{macro}")
        end

        for "c:" <> callback_id <- parse_callbacks(html_tree) do
          callback.("#{module}.#{callback_id}", "Callback", "#{relative_path}#c:#{callback_id}")
        end

        for "t:" <> type <- parse_types(html_tree) do
          callback.("#{module}.#{type}", "Type", "#{relative_path}#t:#{type}")
        end

      is_protocol ->
        callback.(module, "Protocol", "#{relative_path}#content")

      is_exception ->
        callback.(module, "Exception", "#{relative_path}#content")

      is_guide ->
        callback.(module, "Guide", "#{relative_path}#content")

      true ->
        :ok
    end

    html_tree
  end

  defp parse_module(html_tree) do
    html_tree
    |> Floki.find("#content>h1>span")
    |> Floki.text()
  end

  defp parse_functions(html_tree) do
    html_tree
    |> Floki.find("#functions .detail")
    |> Floki.attribute("id")
  end

  defp parse_macros(html_tree) do
    html_tree
    |> Floki.find("#macros .detail")
    |> Floki.attribute("id")
  end

  defp parse_callbacks(html_tree) do
    html_tree
    |> Floki.find(".detail")
    |> Floki.attribute("id")
    |> Enum.filter(&String.starts_with?(&1, "c:"))
  end

  defp parse_types(html_tree) do
    html_tree
    |> Floki.find(".detail")
    |> Floki.attribute("id")
    |> Enum.filter(&String.starts_with?(&1, "t:"))
  end
end
