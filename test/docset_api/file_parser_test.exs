defmodule DocsetApi.FileParserTest do
  @moduledoc """
  The following code dynamically builds unit tests for all of the
  example Fixtures in the fixtures directory. The filenames of each
  fixture are parsed and then they are sorted by which version of the
  documentation library (usually `ExDoc`) is being used. This should
  hopefully aid in finding regression patterns.

  Although macros probably could've been used here, I chose to instead
  use `ExUnit.Case.register_module_attribute/3` to dynamically build
  out a test suite based on a list of fixture filenames.
  """

  require IEx
  require Logger
  alias DocsetApi.FileParser
  use ExUnit.Case

  # Used to store all the fixture filenames. At runtime this attribute
  # is processed and overwritten as a new data structure for use with the tests.
  ExUnit.Case.register_module_attribute(__MODULE__, :fixtures, accumulate: false)

  # Used to temporarily store fixture state while it's looped through
  ExUnit.Case.register_module_attribute(__MODULE__, :fixture, accumulate: false)

  # This is where the magic happens: we define a map with the keys
  # representing fixture files, and the values representing the
  # various types of expectations we have on those files.
  @specs %{
     # This is a behaviour, not an interface, but it's the closest
     # that the docset spec provides.
     #
     # TODO: See about proposing behaviours to be added to the spec.
    "exdoc-0.34-ecto-3.12.4--Ecto.Adapter.html" => %{
      callbacks: [
        {"Ecto.Adapter", "Interface", "Ecto.Adapter.html#content"},
        {"Ecto.Adapter.lookup_meta/1", "Function", "Ecto.Adapter.html#lookup_meta/1"},
        {"Ecto.Adapter.t:adapter_meta/0", "Type", "Ecto.Adapter.html#t:adapter_meta/0"},
        {"Ecto.Adapter.t:t/0", "Type", "Ecto.Adapter.html#t:t/0"}
      ]
    },
    "exdoc-0.34-ecto-3.12.4--Ecto.Query.API.html" => %{
      callbacks: [
        {"Ecto.Query.API", "Module", "Ecto.Query.API.html#content"},
        {"Ecto.Query.API.avg/1", "Function", "Ecto.Query.API.html#avg/1"},
        {"Ecto.Query.API.*/2", "Function", "Ecto.Query.API.html#*/2"},
        {"Ecto.Query.API.+/2", "Function", "Ecto.Query.API.html#+/2"},
        {"Ecto.Query.API.-/2", "Function", "Ecto.Query.API.html#-/2"},
        {"Ecto.Query.API.//2", "Function", "Ecto.Query.API.html#//2"},
        {"Ecto.Query.API.!=/2", "Function", "Ecto.Query.API.html#!=/2"},
        {"Ecto.Query.API.%3C/2", "Function", "Ecto.Query.API.html#%3C/2"},
        {"Ecto.Query.API.%3C=/2", "Function", "Ecto.Query.API.html#%3C=/2"},
        {"Ecto.Query.API.==/2", "Function", "Ecto.Query.API.html#==/2"},
        {"Ecto.Query.API.%3E/2", "Function", "Ecto.Query.API.html#%3E/2"},
        {"Ecto.Query.API.%3E=/2", "Function", "Ecto.Query.API.html#%3E=/2"},
        {"Ecto.Query.API.ago/2", "Function", "Ecto.Query.API.html#ago/2"},
        {"Ecto.Query.API.all/1", "Function", "Ecto.Query.API.html#all/1"},
        {"Ecto.Query.API.and/2", "Function", "Ecto.Query.API.html#and/2"},
        {"Ecto.Query.API.any/1", "Function", "Ecto.Query.API.html#any/1"},
        {"Ecto.Query.API.as/1", "Function", "Ecto.Query.API.html#as/1"},
        {"Ecto.Query.API.coalesce/2", "Function", "Ecto.Query.API.html#coalesce/2"},
        {"Ecto.Query.API.count/0", "Function", "Ecto.Query.API.html#count/0"},
        {"Ecto.Query.API.count/1", "Function", "Ecto.Query.API.html#count/1"},
        {"Ecto.Query.API.count/2", "Function", "Ecto.Query.API.html#count/2"},
        {"Ecto.Query.API.date_add/3", "Function", "Ecto.Query.API.html#date_add/3"},
        {"Ecto.Query.API.datetime_add/3", "Function", "Ecto.Query.API.html#datetime_add/3"},
        {"Ecto.Query.API.exists/1", "Function", "Ecto.Query.API.html#exists/1"},
        {"Ecto.Query.API.field/2", "Function", "Ecto.Query.API.html#field/2"},
        {"Ecto.Query.API.filter/2", "Function", "Ecto.Query.API.html#filter/2"},
        {"Ecto.Query.API.fragment/1", "Function", "Ecto.Query.API.html#fragment/1"},
        {"Ecto.Query.API.from_now/2", "Function", "Ecto.Query.API.html#from_now/2"},
        {"Ecto.Query.API.ilike/2", "Function", "Ecto.Query.API.html#ilike/2"},
        {"Ecto.Query.API.in/2", "Function", "Ecto.Query.API.html#in/2"},
        {"Ecto.Query.API.is_nil/1", "Function", "Ecto.Query.API.html#is_nil/1"},
        {"Ecto.Query.API.json_extract_path/2", "Function",
         "Ecto.Query.API.html#json_extract_path/2"},
        {"Ecto.Query.API.like/2", "Function", "Ecto.Query.API.html#like/2"},
        {"Ecto.Query.API.literal/1", "Function", "Ecto.Query.API.html#literal/1"},
        {"Ecto.Query.API.map/2", "Function", "Ecto.Query.API.html#map/2"},
        {"Ecto.Query.API.max/1", "Function", "Ecto.Query.API.html#max/1"},
        {"Ecto.Query.API.merge/2", "Function", "Ecto.Query.API.html#merge/2"},
        {"Ecto.Query.API.min/1", "Function", "Ecto.Query.API.html#min/1"},
        {"Ecto.Query.API.not/1", "Function", "Ecto.Query.API.html#not/1"},
        {"Ecto.Query.API.or/2", "Function", "Ecto.Query.API.html#or/2"},
        {"Ecto.Query.API.parent_as/1", "Function", "Ecto.Query.API.html#parent_as/1"},
        {"Ecto.Query.API.selected_as/1", "Function", "Ecto.Query.API.html#selected_as/1"},
        {"Ecto.Query.API.selected_as/2", "Function", "Ecto.Query.API.html#selected_as/2"},
        {"Ecto.Query.API.splice/1", "Function", "Ecto.Query.API.html#splice/1"},
        {"Ecto.Query.API.struct/2", "Function", "Ecto.Query.API.html#struct/2"},
        {"Ecto.Query.API.sum/1", "Function", "Ecto.Query.API.html#sum/1"},
        {"Ecto.Query.API.type/2", "Function", "Ecto.Query.API.html#type/2"},
        {"Ecto.Query.API.values/2", "Function", "Ecto.Query.API.html#values/2"}
      ]
    },

    "exdoc-0.34-ecto-3.12.4--getting-started.html" => %{
      callbacks: [{"Getting Started", "Guide", "getting-started.html#content"}]
    },

    "exdoc-0.34-ecto-3.12.4--Ecto.QueryError.html" => %{
      callbacks: [{"Ecto.QueryError", "Exception", "Ecto.QueryError.html#content"}]
    },

    # This is not a guide, but a "cheatsheet", which we put in the guide category.
    "exdoc-0.34-ecto-3.12.4--crud.html" => %{
      callbacks: [{"Basic CRUD", "Guide", "crud.html#content"}]
    }

  }

  # Split between fixtures specs & html filename
  @fixtures Map.keys(@specs)
            |> Enum.map(&{&1, String.split(&1, "--")})
            |> Enum.map(fn
              {fixture_filename, [fixture, filename]} ->
                [doc, doc_version, pkg, pkg_version] = String.split(fixture, "-")

                # Build a data structure for the metadata associated with a fixture.
                %{
                  documenting_tool: doc,
                  documenting_tool_version: doc_version,
                  pkg: {pkg, pkg_version},
                  document_filename: filename,
                  fixture_filename: fixture_filename
                }

              unparseable ->
                raise("Cannot parse #{inspect(unparseable)}. Please check its format.")
            end)
            # Group the results by documentation tool name &
            # version, so that they can be grouped into an exunit
            # describe block together.
            |> Enum.group_by(
              &"#{&1.documenting_tool}-#{&1.documenting_tool_version}",
              &%{
                fixture_filename: &1.fixture_filename,
                document_filename: &1.document_filename,
                pkg: &1.pkg,
                specs: Map.fetch!(@specs, &1.fixture_filename)
              }
            )

  for {doc, fixtures} <- @fixtures do
    describe "[#{doc}]" do
      for %{document_filename: filename, pkg: {pkg, pkg_version}} = fixture <- fixtures do
        # While filename is in scope when the first argument of the
        # test call is being interpolated, this is not the case for
        # inside the block.
        #
        # Intead, we set the fixture to the @fixture module attribute,
        # which adds it to the test context.
        @fixture fixture

        test "[#{pkg}-#{pkg_version}] -> Testing #{filename} fixture", %{
          registered: %{
            fixture: %{specs: specs, fixture_filename: filename, document_filename: doc}
          }
        } do
          Process.register(self(), :test)

          file_path = Path.join([File.cwd!(), "test/support/fixtures", filename])

          {:ok, html} =
            file_path
            |> File.read!()
            |> Floki.parse_document()

          FileParser.parse_zeal_navigation(html, doc, fn name, type, path ->
            # dbg({name, type, path})
            # Tally the states by sending them to the `:test` process to
            # be received and asserted against.
            send(:test, {:called_back, name, type, path})
          end)

          for {name, type, path} <- specs[:callbacks] do
            assert_receive {:called_back, ^name, ^type, ^path}
          end

          # Check the :test mailbox and if there are any callbacks
          # which weren't accounted for, raise an error, since we
          # didn't expect to receive them and haven't implemented
          # expectations for them.  This way there's a nice workflow.
          [message_queue_len: queue_len, messages: messages] =
            Process.info(
              Process.whereis(:test),
              [:message_queue_len, :messages]
            )

          if queue_len > 0 do
            raise """

            There were #{queue_len} unexpected callback(s). Should
            they be added to the expectations list?

            #{for msg <- messages, do: inspect(msg) <> "\n"}

            """
          end

          Process.unregister(:test)
        end
      end
    end
  end

  # Unset the fixture module attribute once we've finished misusing it.
  @fixture nil
end
