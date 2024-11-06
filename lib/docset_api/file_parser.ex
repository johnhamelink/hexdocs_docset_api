defmodule DocsetApi.FileParser do
  require Logger
  require IEx

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
      # Extension
      # Field
      # File
      # Filter
      # Framework
      # Global

      # Function
      "Function" => %{
        type: :inside_file,

        # The unique identifier for the function we are recording. It
        # should contain the entire namespace.
        name: &("#{&1}.#{&2}"),

        # A function which will find function IDs on the html tree (it includes arity)
        finder: &(Floki.attribute(Floki.find(&1, "#functions .detail"), "id")),

        # The relative path to the content to navigate to
        content_selector: &("#{&1}##{&2}")
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
        predicate: fn(html) ->
          body_tag = Floki.find(html, "body")
          class_items =
            Floki.attribute(body_tag, "class")
            |> Enum.map(&String.split(&1, " "))

          "extras" in Floki.attribute(body_tag, "data-type") and
            "page-extra" in class_items
        end,
        content_selector: &("#{&1}#content")
      },
  
      # Hook
      # Instance
      # Instruction

      # Interface
      #
      # Obviously an interface is not a behaviour, but it's close
      # enough to continue on, and I can see about having behaviours
      # added later.
      "Interface" => %{
        type: :whole_file,
        predicate: fn(html) ->
          body_tag = Floki.find(html, "body")
          class_items =
            Floki.attribute(body_tag, "class")
            |> Enum.flat_map(&String.split(&1, " "))

          "modules" in Floki.attribute(body_tag, "data-type") and
            "page-behaviour" in class_items
        end,
        finder: fn(html) ->
          Floki.find(html, "div#top-content span")
          |> List.last
          |> Floki.text
          |> String.trim
        end,
        content_selector: &("#{&1}#content")
      },
      # Keyword
      # Library
      # Literal
      # Macro
      # Method
      # Mixin
      # Modifier
      # Module
      "Module" => %{
        type: :whole_file,
        predicate: fn(html) ->
          body_tag = Floki.find(html, "body")
          "modules" in Floki.attribute(body_tag, "data-type") and
            "page-module" in Floki.attribute(body_tag, "class")
        end,
        finder: fn(html) ->
          Floki.find(html, "div#top-content span")
          |> List.last
          |> Floki.text
          |> String.trim
        end,
        content_selector: &("#{&1}#content")
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
      # Property
      # Protocol
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

      # Type
      "Type" => %{
        type: :inside_file,

        # The unique identifier for the function we are recording. It
        # should contain the entire namespace.
        name: &("#{&1}.#{&2}"),

        # A function which will find function IDs on the html tree
        finder: &(Floki.attribute(Floki.find(&1, ".types-list .detail"), "id")),

        # The relative path to the content to navigate to
        content_selector: &("#{&1}##{&2}")
      }

      # Union
      # Value
      # Variable
      # Word
    }
  end

  @spec parse_zeal_navigation(Floki.html_tree(), binary(), fun()) :: Floki.html_tree()
  def parse_zeal_navigation(html, file_path, callback) when is_function(callback) do
    for {type, parser} <- parsers() do
      Logger.debug "Looking for #{type} types"
      case type do
        symbol when symbol in ~w[Module Interface] ->
          symbol == "Interface" && IEx.pry
          if parser.predicate.(html) do
            callback.(
              parser.finder.(html),
              type,
              parser.content_selector.(file_path)
            )
          else
            Logger.warning "Couldn't find evidence of #{type} in the file, moving on"
          end

        # Inline Types?
        symbol when symbol in ~w[Function Type] ->

          # Fetch the module associated with this file
          #
          # TODO: Cache this, probably, since the module:function
          #       ratio will be highly skewed
          {:ok, module_parser} = Map.fetch(parsers(), "Module")
          module = module_parser.finder.(html)

          if module == nil do
            raise """
            Could not find module for a function. This is probably a
            bug?
            """
          end

          for id <- parser.finder.(html) do
            callback.(
              parser.name.(module, id),
              type,
              parser.content_selector.(file_path, id)
            )
          end
        _ ->
          Logger.warning "Unimplemented: #{type}. Skipping."
      end
    end


    # cond do
    #   module != "" and not is_guide and not is_exception and not is_protocol ->
    #     callback.(module, "Module", "#{file_path}#content")

    #     for function <- parse_functions(html) do
    #       callback.("#{module}.#{function}", "Function", "#{file_path}##{function}")
    #     end

    #     for macro <- parse_macros(html) do
    #       callback.("#{module}.#{macro}", "Macro", "#{file_path}##{macro}")
    #     end

    #     for "c:" <> callback_id <- parse_callbacks(html) do
    #       callback.("#{module}.#{callback_id}", "Callback", "#{file_path}#c:#{callback_id}")
    #     end

    #     for "t:" <> type <- parse_types(html) do
    #       callback.("#{module}.#{type}", "Type", "#{file_path}#t:#{type}")
    #     end

    #   true ->
    #     :ok
    # end

    html
  end
end
