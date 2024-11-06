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
    "exdoc-0.34-ecto-3.12.4--Ecto.Adapter.html" => %{
      callbacks: [
        {"Ecto.Adapter.lookup_meta/1", "Function", "Ecto.Adapter.html#lookup_meta/1"},
        {"Ecto.Adapter.t:adapter_meta/0", "Type", "Ecto.Adapter.html#t:adapter_meta/0"},
        {"Ecto.Adapter.t:t/0", "Type", "Ecto.Adapter.html#t:t/0"},
        {"Ecto.Adapter", "Interface", "Ecto.Adapter.html#content"}
      ]
    },
    "exdoc-0.34-ecto-3.12.4--Ecto.Query.API.html" => %{
      callbacks: [
      ]
    },
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

          # Tally the states by sending them to the `:test` process to
          # be received and asserted against.
          callback = fn name, type, path ->
            dbg({name, type, path})
            send(:test, {:called_back, name, type, path})
          end

          FileParser.parse_zeal_navigation(html, doc, callback)

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
