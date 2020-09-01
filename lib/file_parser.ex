defmodule DocsetApi.FileParser do
  require Logger

  defp parse_module(html) do
    html
    |> Floki.find("#content>h1")
    |> Enum.map(fn {tag, attrs, children} ->
      children =
        children
        |> Enum.reject(fn
          {_tag, _attrs, _children} -> true
          text when is_bitstring(text) -> false
        end)

      {tag, attrs, children}
      |> Floki.text()
      |> String.trim()
    end)
    |> Enum.reject(&(&1 =~ " "))

    # Reject all headers with spaces
    # in them - they're not modules
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

  def parse_file(file, files_dir, callback) when is_function(callback) do
    case Path.extname(file) do
      ".html" ->
        Logger.info("parse #{file}")

        html = Floki.parse_document!(File.read!(file))
        relative_file = Path.relative_to(file, files_dir)

        module = parse_module(html)

        unless module == [] do
          functions = parse_functions(html)
          macros = parse_macros(html)

          callback.(module, "Module", "#{relative_file}#content")

          for function <- functions do
            callback.(
              "#{module}.#{function}",
              "Function",
              "#{relative_file}##{function}"
            )
          end

          for macro <- macros do
            callback.(
              "#{module}.#{macro}",
              "Macro",
              "#{relative_file}##{macro}"
            )
          end
        end

      _ ->
        Logger.info("skip #{file}")
    end
  end
end
