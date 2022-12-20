defmodule DocsetApi.FileParser do
  require Logger
  def parse_file(file, files_dir, callback) when is_function(callback) do
    case Path.extname(file) do
      ".html" ->
        Logger.debug("parse #{file}")

        html = Floki.parse_document! File.read! file
        relative_file = Path.relative_to(file, files_dir)

        module = parse_module(html)

        unless module =~ " " do
          callback.(module, "Module", "#{relative_file}#content")

          for function <- parse_functions(html) do
            callback.("#{module}.#{function}", "Function", "#{relative_file}##{function}")
          end

          for macro <- parse_macros(html) do
            callback.("#{module}.#{macro}", "Macro", "#{relative_file}##{macro}")
          end

          for "c:" <> callback_id <- parse_callbacks(html) do
            callback.("#{module}.#{callback_id}", "Callback", "#{relative_file}#c:#{callback_id}")
          end

          for "t:" <> type <- parse_types(html) do
            callback.("#{module}.#{type}", "Type", "#{relative_file}#t:#{type}")
          end
        end

      _ ->
        Logger.debug("skip #{file}")
    end
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
