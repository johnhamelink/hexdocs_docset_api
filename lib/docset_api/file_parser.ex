defmodule DocsetApi.FileParser do
  require Logger
  require IEx

  def whole_file_finder(html) do
    Floki.find(html, "title")
    |> Floki.text()
    |> String.trim()
    |> String.split(" — ")
    |> List.first()
  end

  def parsers do
    %{
      # Annotation
      # Attribute
      # Binding
      # Builtin
      # Callback
      # Category
      # Class
      # Command
      # Component
      # Constant
      # Constructor
      # Define
      # Delegate
      # Diagram
      # Directive
      # Element
      # Entry
      # Enum
      # Environment
      # Error
      # Event
      # Exception
      "Exception" => %{
        type: :whole_file,
        # finder: fn html ->
        #   IEx.pry
        #   Floki.attribute(Floki.find(html, ""), "id")
        # end,

        # This function is used to check if a page "is a guide" or "is
        # a module".
        predicate: fn html ->
          body_tag = Floki.find(html, "body")

          class_items =
            Floki.attribute(body_tag, "class")
            |> Enum.flat_map(&String.split(&1, " "))

          "modules" in Floki.attribute(body_tag, "data-type") and
            "page-exception" in class_items
        end,
        finder: &whole_file_finder/1,
        content_selector: &"#{&1}#content"
      },

      # Extension
      # Field
      # File
      # Filter
      # Framework
      # Global

      # Function
      "Function" => %{
        type: :inline,

        # The unique identifier for the function we are recording. It
        # should contain the entire namespace.
        name: &"#{&1}.#{&2}",

        # A function which will find function IDs on the html tree (it includes arity)
        finder: &Floki.attribute(Floki.find(&1, "#functions .detail"), "id"),

        # The relative path to the content to navigate to
        content_selector: &"#{&1}##{&2}"
      },

      # Guide
      "Guide" => %{
        type: :whole_file,
        # finder: fn html ->
        #   IEx.pry
        #   Floki.attribute(Floki.find(html, ""), "id")
        # end,

        # This function is used to check if a page "is a guide" or "is
        # a module".
        predicate: fn html ->
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
        end,
        finder: &whole_file_finder/1,
        content_selector: &"#{&1}#content"
      },

      # Hook
      # Instance
      # Instruction

      # Obviously an interface is not a behaviour, but it's close
      # enough to continue on, and I can see about having behaviours
      # added later.
      "Interface" => %{
        type: :whole_file,
        predicate: fn html ->
          body_tag = Floki.find(html, "body")

          class_items =
            Floki.attribute(body_tag, "class")
            |> Enum.flat_map(&String.split(&1, " "))

          "modules" in Floki.attribute(body_tag, "data-type") and
            "page-behaviour" in class_items
        end,
        finder: &whole_file_finder/1,
        content_selector: &"#{&1}#content"
      },
      # Keyword
      # Library
      # Literal
      # Macro
      # Method
      # Mixin
      # Modifier
      "Module" => %{
        type: :whole_file,
        predicate: fn html ->
          body_tag = Floki.find(html, "body")

          class_items =
            Floki.attribute(body_tag, "class")
            |> Enum.flat_map(&String.split(&1, " "))

          "modules" in Floki.attribute(body_tag, "data-type") and
            "page-module" in class_items
        end,
        finder: &whole_file_finder/1,
        content_selector: &"#{&1}#content"
      },
      # Namespace
      # Notation
      # Object
      # Operator
      # Option
      # Package
      # Parameter
      # Plugin

      # Procedure
      # We'll use Procedure for Tasks
      "Procedure" => %{
        type: :whole_file,
        predicate: fn html ->
          body_tag = Floki.find(html, "body")

          class_items =
            Floki.attribute(body_tag, "class")
            |> Enum.flat_map(&String.split(&1, " "))

          "tasks" in Floki.attribute(body_tag, "data-type") and
            "page-task" in class_items
        end,
        finder: &whole_file_finder/1,
        content_selector: &"#{&1}#content"
      },

      # Property

      # Protocol
      "Protocol" => %{
        type: :whole_file,
        predicate: fn html ->
          body_tag = Floki.find(html, "body")

          class_items =
            Floki.attribute(body_tag, "class")
            |> Enum.flat_map(&String.split(&1, " "))

          "modules" in Floki.attribute(body_tag, "data-type") and
            "page-protocol" in class_items
        end,
        finder: &whole_file_finder/1,
        content_selector: &"#{&1}#content"
      },

      # Provider
      # Provisioner
      # Query
      # Record
      # Resource
      # Sample
      # Section
      # Service
      # Setting
      # Shortcut
      # Statement
      # Struct
      # Style
      # Subroutine
      # Tag
      # Test
      # Trait

      "Type" => %{
        type: :inline,

        # The unique identifier for the function we are recording. It
        # should contain the entire namespace.
        name: &("#{&1}." <> String.replace_prefix(&2, "t:", "")),

        # A function which will find function IDs on the html tree
        finder: &Floki.attribute(Floki.find(&1, ".types-list .detail"), "id"),

        # The relative path to the content to navigate to
        content_selector: &"#{&1}##{&2}"
      }

      # Union
      # Value
      # Variable
      # Word
    }
  end

  def parsers(type_filter) do
    Enum.filter(parsers(), fn
      {_key, %{type: ^type_filter}} -> true
      _ -> false
    end)
  end

  def parse_file_type(html, file_path, callback) do
    # Determine "whole-file" type, and use that to define the namespace
    parsers(:whole_file)
    # I wonder - it might be necessary to allow multiple for
    # whole_file types per file. Leaving this comment here just to
    # remind me where to adjust this if necessary.
    |> Enum.find_value(fn {type, parser} ->
      Logger.debug("Checking if file is of type #{type}")
      # if file_path == "crud.html", do: IEx.pry()

      if parser.predicate.(html) do
        name = parser.finder.(html)
        file_path = parser.content_selector.(file_path)

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

  def parse_inside_file(html, namespace, file_path, callback) do
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

      for id <- parser.finder.(html) do
        # IO.inspect(id, label: "ID")
        # IO.inspect(namespace, label: "Namespace")
        # IEx.pry
        callback.(
          parser.name.(namespace, id),
          type,
          parser.content_selector.(file_path, id)
        )
      end

      :ok
    end
  end

  @spec parse(Floki.html_tree(), binary(), fun()) :: Floki.html_tree()
  def parse(html, file_path, callback) when is_function(callback) do
    case parse_file_type(html, file_path, callback) do
      {namespace, _type, _file_path} ->
        parse_inside_file(html, namespace, file_path, callback)

      nil ->
        Logger.warning(
          "Could not categorise #{file_path}. If this is surprising then consider it a bug. Moving on."
        )

      other ->
        Logger.warning("Could not categorise response #{inspect(other)}. This is a bug.")
    end

    html
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

  def identify_check_for(:exdoc, html) do
    ["ExDoc", version] =
      Floki.find(html, "meta[name=\"generator\"]")
      |> Floki.attribute("content")
      |> Floki.text()
      |> String.trim()
      |> String.split(" v")

    {:exdoc, version}
  end
end
