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

  alias DocsetApi.FileParser
  use ExUnit.Case
  import ExUnit.CaptureLog

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
    "exdoc-0.34.2-ecto-3.12.4--Ecto.Adapter.html" => %{
      callbacks: [
        {"Ecto.Adapter", "Interface", "Ecto.Adapter.html#content"},
        {"Ecto.Adapter.lookup_meta/1", "Function", "Ecto.Adapter.html#lookup_meta/1"},
        {"Ecto.Adapter.adapter_meta/0", "Type", "Ecto.Adapter.html#t:adapter_meta/0"},
        {"Ecto.Adapter.t/0", "Type", "Ecto.Adapter.html#t:t/0"}
      ]
    },
    "exdoc-0.34.2-ecto-3.12.4--Ecto.Query.API.html" => %{
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
    "exdoc-0.34.2-ecto-3.12.4--getting-started.html" => %{
      callbacks: [{"Getting Started", "Guide", "getting-started.html#content"}]
    },
    "exdoc-0.34.2-ecto-3.12.4--Ecto.QueryError.html" => %{
      callbacks: [{"Ecto.QueryError", "Exception", "Ecto.QueryError.html#content"}]
    },
    # This is not a guide, but a "cheatsheet", which we put in the guide category.
    "exdoc-0.34.2-ecto-3.12.4--crud.html" => %{
      callbacks: [{"Basic CRUD", "Guide", "crud.html#content"}]
    },
    "exdoc-0.34.0-phoenix-1.7.14--Phoenix.Param.html" => %{
      callbacks: [
        {"Phoenix.Param", "Protocol", "Phoenix.Param.html#content"},
        {"Phoenix.Param.to_param/1", "Function", "Phoenix.Param.html#to_param/1"},
        {"Phoenix.Param.t/0", "Type", "Phoenix.Param.html#t:t/0"}
      ]
    },
    "exdoc-0.34.0-phoenix-1.7.14--Phoenix.Socket.Transport.html" => %{
      callbacks: [
        {"Phoenix.Socket.Transport", "Interface", "Phoenix.Socket.Transport.html#content"},
        {"Phoenix.Socket.Transport.check_origin/5", "Function",
         "Phoenix.Socket.Transport.html#check_origin/5"},
        {"Phoenix.Socket.Transport.check_subprotocols/2", "Function",
         "Phoenix.Socket.Transport.html#check_subprotocols/2"},
        {"Phoenix.Socket.Transport.code_reload/3", "Function",
         "Phoenix.Socket.Transport.html#code_reload/3"},
        {"Phoenix.Socket.Transport.connect_info/3", "Function",
         "Phoenix.Socket.Transport.html#connect_info/3"},
        {"Phoenix.Socket.Transport.transport_log/2", "Function",
         "Phoenix.Socket.Transport.html#transport_log/2"},
        {"Phoenix.Socket.Transport.state/0", "Type", "Phoenix.Socket.Transport.html#t:state/0"}
      ]
    },
    "exdoc-0.28.6-jason-1.5.0.alpha2--Jason.EncodeError.html" => %{
      callbacks: [
        {"Jason.EncodeError", "Exception", "Jason.EncodeError.html#content"},
        {"Jason.EncodeError.new/1", "Function", "Jason.EncodeError.html#new/1"},
        {"Jason.EncodeError.t/0", "Type", "Jason.EncodeError.html#t:t/0"}
      ]
    },
    "exdoc-0.28.6-jason-1.5.0.alpha2--Jason.OrderedObject.html" => %{
      callbacks: [
        {"Jason.OrderedObject", "Module", "Jason.OrderedObject.html#content"},
        {"Jason.OrderedObject.__struct__/0", "Function", "Jason.OrderedObject.html#__struct__/0"},
        {"Jason.OrderedObject.new/1", "Function", "Jason.OrderedObject.html#new/1"},
        {"Jason.OrderedObject.t/0", "Type", "Jason.OrderedObject.html#t:t/0"}
      ]
    },
    "exdoc-0.28.6-jason-1.5.0.alpha2--Jason.Encoder.html" => %{
      callbacks: [
        {"Jason.Encoder", "Protocol", "Jason.Encoder.html#content"},
        {"Jason.Encoder.encode/2", "Function", "Jason.Encoder.html#encode/2"},
        {"Jason.Encoder.opts/0", "Type", "Jason.Encoder.html#t:opts/0"},
        {"Jason.Encoder.t/0", "Type", "Jason.Encoder.html#t:t/0"}
      ]
    },
    "exdoc-0.25.5-httpoison-2.2.1--HTTPoison.AsyncChunk.html" => %{
      callbacks: [
        {"HTTPoison.AsyncChunk", "Module", "HTTPoison.AsyncChunk.html#content"},
        {"HTTPoison.AsyncChunk.t/0", "Type", "HTTPoison.AsyncChunk.html#t:t/0"}
      ]
    },
    "exdoc-0.25.5-httpoison-2.2.1--HTTPoison.Base.html" => %{
      callbacks: [
        {"HTTPoison.Base", "Interface", "HTTPoison.Base.html#content"},
        {"HTTPoison.Base.maybe_process_form/1", "Function", "HTTPoison.Base.html#maybe_process_form/1"},
        {"HTTPoison.Base.body/0", "Type", "HTTPoison.Base.html#t:body/0"},
        {"HTTPoison.Base.headers/0", "Type", "HTTPoison.Base.html#t:headers/0"},
        {"HTTPoison.Base.method/0", "Type", "HTTPoison.Base.html#t:method/0"},
        {"HTTPoison.Base.options/0", "Type", "HTTPoison.Base.html#t:options/0"},
        {"HTTPoison.Base.params/0", "Type", "HTTPoison.Base.html#t:params/0"},
        {"HTTPoison.Base.request/0", "Type", "HTTPoison.Base.html#t:request/0"},
        {"HTTPoison.Base.response/0", "Type", "HTTPoison.Base.html#t:response/0"},
        {"HTTPoison.Base.url/0", "Type", "HTTPoison.Base.html#t:url/0"}
      ]
    },
    "exdoc-0.25.5-httpoison-2.2.1--HTTPoison.Error.html" => %{
      callbacks: [
        {"HTTPoison.Error", "Exception", "HTTPoison.Error.html#content"},
        {"HTTPoison.Error.message/1", "Function", "HTTPoison.Error.html#message/1"},
        {"HTTPoison.Error.t/0", "Type", "HTTPoison.Error.html#t:t/0"}
      ]
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
                doc: {
                  # This will always be the first instance of this atom
                  String.to_atom(&1.documenting_tool),
                  &1.documenting_tool_version
                },
                specs: Map.fetch!(@specs, &1.fixture_filename)
              }
            )

  for {doc, fixtures} <- @fixtures do
    describe "fixture: [#{String.replace(doc, "-", " ")}]" do
      for %{document_filename: filename, pkg: {pkg, pkg_version}} = fixture <- fixtures do
        # While filename is in scope when the first argument of the
        # test call is being interpolated, this is not the case for
        # inside the block.
        #
        # Intead, we set the fixture to the @fixture module attribute,
        # which adds it to the test context.
        @fixture fixture

        # For each ExUnit version, build a test to ensure that it can be
        # identified correctly.
        test "[#{pkg} #{pkg_version}] [ID] " <> filename, %{
          registered: %{fixture: %{doc: {doc_n, doc_v}, fixture_filename: filename}}
        } do
          file_path = Path.join([File.cwd!(), "test/support/fixtures", filename])
          {:ok, html} =
            file_path
            |> File.read!()
            |> Floki.parse_document()

          assert {doc_n, Version.parse!(doc_v)} == FileParser.identify_documenting_tool_version(html)
        end

        # For each ExUnit version, build a suite of tests to
        # ensure indexing can be done correctly.
        test "[#{pkg} #{pkg_version}] [INDEX] " <> filename, %{
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

          logs =
            capture_log(fn ->
              FileParser.parse(html, doc, fn name, type, path ->
                # dbg({name, type, path})
                # Tally the states by sending them to the `:test` process to
                # be received and asserted against.
                send(:test, {:called_back, name, type, path})
              end)
            end)

          # Ensure we have categorised everything
          if logs =~ "Could not categorise" do
            raise """
            There are fixtures which aren't being categorised by the
            test, and so haven't been implemented correctly. This is a
            bug.

            #{logs}
            """
          end


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
