defmodule DocsetApi.FileParser do
  require Logger
  require IEx

  @banned_files [
     "404.html",
     "search.html"
   ]

  defp whole_file_finder(html) do
    Floki.find(html, "title")
    |> Floki.text()
    |> String.trim()
    |> String.split(" — ")
    |> List.first()
  end

  defp exdoc_25_is_type?(html, expected) do
    body_tag = Floki.find(html, "body")

    module_type =
      Floki.find(html, "div.content-inner>h1>small")
      |> List.first
      |> Floki.text
      |> String.trim

    if expected == "module" do
      "modules" in Floki.attribute(body_tag, "data-type") and
        module_type not in module_subtypes(:downcase)
    else
      "modules" in Floki.attribute(body_tag, "data-type") and
        module_type == expected
    end
  end

  defp exdoc_is_type?(html, expected) do
    body_tag = Floki.find(html, "body")

    class_items =
      Floki.attribute(body_tag, "class")
      |> Enum.flat_map(&String.split(&1, " "))

    "modules" in Floki.attribute(body_tag, "data-type") and
      "page-#{expected}" in class_items
  end

  def identify_check_for(:exdoc, html) do
    ["ExDoc", version] =
      Floki.find(html, "meta[name=\"generator\"]")
      |> Floki.attribute("content")
      |> Floki.text()
      |> String.trim()
      |> String.split(" v")

    {:exdoc, Version.parse!(version)}
  end

  # Other available types to chose from:
  #
  # Annotation Attribute Binding Builtin Callback Category Class
  # Command Component Constant Constructor Define Delegate Diagram
  # Directive Element Entry Enum Environment Error Event Extension
  # Field File Filter Framework Global Hook Instance Instruction
  # Keyword Library Literal Macro Method Mixin Modifier Namespace
  # Notation Object Operator Option Package Parameter Plugin
  # Property Provider Provisioner Query Record Resource Sample
  # Section Service Setting Shortcut Statement Struct Style
  # Subroutine Tag Test Trait Union Value Variable Word
  #
  # Taken from https://kapeli.com/docsets#supportedentrytypes
  def parsers do

    %{
      "Exception" => %{
        type: :whole_file,
        # Determines whether the file in question is of
        # type "exception" or not.
        is_type?: fn
          {:exdoc, %Version{major: 0, minor: m, patch: _}} when m > 25 ->
            &exdoc_is_type?(&1, "exception")
          {:exdoc, %Version{major: 0, minor: 25, patch: _}} ->
            &exdoc_25_is_type?(&1, "exception")
        end,
        # What is the ID of this thing?
        id: fn
          {:exdoc, _version} -> &whole_file_finder(&1)
        end,
        # Where is the content we wish to keep?
        path: fn
          {:exdoc, _version} -> &"#{&1}#content"
        end
      },

      "Function" => %{
        type: :inline,

        # The unique identifier for the function we are recording. It
        # should contain the entire namespace.
        name: fn {:exdoc, _} -> &"#{&1}.#{&2}" end,

        # A function which will find function IDs on the html tree (it includes arity)
        id: fn {:exdoc, _} -> &Floki.attribute(Floki.find(&1, "#functions .detail"), "id") end,

        # The relative path to the content to navigate to
        path: fn {:exdoc, _} -> &"#{&1}##{&2}" end
      },

      "Guide" => %{
        type: :whole_file,
        is_type?: fn
          {:exdoc, %Version{major: 0, minor: m, patch: _}} when m > 25 ->
            fn html ->
              body_tag = Floki.find(html, "body")

              class_items =
                Floki.attribute(body_tag, "class")
                |> Enum.flat_map(&String.split(&1, " "))
                |> MapSet.new()

              class_intersection =
                MapSet.new(["page-extra", "page-cheatmd"])
                |> MapSet.intersection(class_items)

              "extras" in Floki.attribute(body_tag, "data-type") and
                MapSet.size(class_intersection) > 0
            end
          {:exdoc, %Version{major: 0, minor: 25, patch: _}} ->
            fn html ->
              # FIXME: Is this specific enough?
              body_tag = Floki.find(html, "body")
              "extras" in Floki.attribute(body_tag, "data-type")
            end
        end,
        id: fn
          {:exdoc, _} -> &whole_file_finder/1
        end,
        path: fn
          {:exdoc, _} -> &"#{&1}#content"
        end
      },

      # Obviously an interface is not a behaviour, but it's close
      # enough to continue on, and I can see about having behaviours
      # added later.
      "Interface" => %{
        type: :whole_file,
        is_type?: fn
          {:exdoc, %Version{major: 0, minor: m, patch: _}} when m > 25 ->
            &exdoc_is_type?(&1, "behaviour")
          {:exdoc, %Version{major: 0, minor: 25, patch: _}} ->
            &exdoc_25_is_type?(&1, "behaviour")
        end,
        id: fn
          {:exdoc, _} -> &whole_file_finder/1
        end,
        path: fn
          {:exdoc, _} -> &"#{&1}#content"
        end
      },

      "Module" => %{
        type: :whole_file,
        is_type?: fn
          {:exdoc, %Version{major: 0, minor: m, patch: _}} when m > 25 ->
            &exdoc_is_type?(&1, "module")
          {:exdoc, %Version{major: 0, minor: 25, patch: _}} ->
            &exdoc_25_is_type?(&1, "module")
        end,
        id: fn
          {:exdoc, _} -> &whole_file_finder/1
        end,
        path: fn
          {:exdoc, _} -> &"#{&1}#content"
        end
      },
      
      # FIXME: We'll use Procedure for Tasks since Tasks isn't
      #        available
      "Procedure" => %{
        type: :whole_file,
        is_type?: fn
          {:exdoc, %Version{major: 0, minor: m, patch: _}} when m > 25 ->
            &exdoc_is_type?(&1, "task")
          {:exdoc, %Version{major: 0, minor: 25, patch: _}} ->
            &exdoc_25_is_type?(&1, "task")
        end,
        id: fn
          {:exdoc, _} -> &whole_file_finder/1
        end,
        path: fn
          {:exdoc, _} -> &"#{&1}#content"
        end
      },

      "Protocol" => %{
        type: :whole_file,
        is_type?: fn
          {:exdoc, %Version{major: 0, minor: m, patch: _}} when m > 25 ->
            &exdoc_is_type?(&1, "protocol")
          {:exdoc, %Version{major: 0, minor: 25, patch: _}} ->
            &exdoc_25_is_type?(&1, "protocol")
        end,
        id: fn
          {:exdoc, _} -> &whole_file_finder/1
        end,
        path: fn
          {:exdoc, _} -> &"#{&1}#content"
        end
      },

      "Type" => %{
        type: :inline,

        # The unique identifier for the function we are recording. It
        # should contain the entire namespace.
        name: fn
          {:exdoc, _} -> &("#{&1}." <> String.replace_prefix(&2, "t:", ""))
        end,

        # A function which will find function IDs on the html tree
        id: fn
          {:exdoc, _} ->  &Floki.attribute(Floki.find(&1, ".types-list .detail"), "id")
        end,

        # The relative path to the content to navigate to
        path: fn
          {:exdoc, _} -> &"#{&1}##{&2}"
        end
      }
    }
  end

  @spec identify_documenting_tool_version(Floki.html_tree()) :: {atom(), binary()}
  def identify_documenting_tool_version(html) do
    # Try various different
    Enum.find_value(
      [
        fn -> identify_check_for(:exdoc, html) end
      ],
      fn x -> x.() end
    )
  end

  def module_subtypes(:downcase) do
    Enum.map(module_subtypes(), &String.downcase/1)
  end

  def module_subtypes(:upcase) do
    Enum.map(module_subtypes(), &String.upcase/1)
  end

  def module_subtypes() do
    parsers()
    |> Map.filter(fn
      {_key, %{type: :whole_file}} -> true
      _ -> false
    end)
    |> Map.keys
  end

  def parsers(type_filter) do
    Enum.filter(parsers(), fn
      {_key, %{type: ^type_filter}} -> true
      _ -> false
    end)
  end

  def parse_file_type(html, doc, file_path, callback) do
    # Determine "whole-file" type, and use that to define the namespace
    parsers(:whole_file)
    # I wonder - it might be necessary to allow multiple for
    # whole_file types per file. Leaving this comment here just to
    # remind me where to adjust this if necessary.
    |> Enum.find_value(fn {type, parser} ->
      Logger.debug("Checking if file is of type #{type}")
      # if file_path == "crud.html", do: IEx.pry()

      is_type? = parser.is_type?.(doc)
      id = parser.id.(doc)
      path = parser.path.(doc)

      if is_type?.(html) do
        name = id.(html)
        file_path = path.(file_path)

        # Trigger the callback against this matched file type, so that
        # it's added to the database.
        callback.(name, type, file_path)

        # Return the detection state
        {name, type, file_path}
      else
        # Keep searching
        false
      end
    end)
  end

  def parse_inside_file(html, doc, namespace, file_path, callback) do
    # Loop through the inline parsers
    for {type, parser} <- parsers(:inline) do
      Logger.debug("Looking for #{type} types")
      # Fetch the module associated with this file
      #
      # TODO: Cache this, probably, since the module:function
      #       ratio will be highly skewed
      if namespace == nil do
        raise """
            Could not find namespace for a #{file_path}. This is probably a
            bug?
        """
      end

      id = parser.id.(doc)
      name = parser.name.(doc)
      path = parser.path.(doc)

      for id <- id.(html) do
        # IO.inspect(id, label: "ID")
        # IO.inspect(namespace, label: "Namespace")
        # IEx.pry
        callback.(
          name.(namespace, id),
          type,
          path.(file_path, id)
        )
      end

      :ok
    end
  end

  @spec parse(Floki.html_tree(), binary(), fun()) :: Floki.html_tree()
  def parse(html, file_path, callback) when is_function(callback) do
    doc = identify_documenting_tool_version(html)

    if file_path not in @banned_files do
      case parse_file_type(html, doc, file_path, callback) do
        {namespace, _type, _file_path} ->
          parse_inside_file(html, doc, namespace, file_path, callback)

        nil ->
          Logger.warning(
            "Could not categorise #{file_path}. If this is surprising then consider it a bug. Moving on."
          )

        other ->
          Logger.warning("Could not categorise response #{inspect(other)}. This is a bug.")
      end
    else
        Logger.warning("Ignoring #{file_path} since it's a banned file.")
    end

    html
  end
end
