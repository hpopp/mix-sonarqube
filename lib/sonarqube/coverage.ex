defmodule SonarQube.Coverage do
  @moduledoc """
  Cover tool that converts Elixir test coverage to SonarQube's generic
  coverage XML format.

  ## Setup

  Configure as the cover tool in your `mix.exs`:

      def project do
        [
          test_coverage: [tool: SonarQube.Coverage]
        ]
      end

  Then run:

      $ mix test --cover
      # or
      $ mix sonarqube.coverage

  This generates `cover/sonar-coverage.xml` which SonarQube can import
  via the `sonar.coverageReportPaths` property.

  ## Options

  Options are passed via `test_coverage` in `mix.exs`:

    * `:sonar_xml` - Output path for the XML file. Defaults to `"cover/sonar-coverage.xml"`.

  ## Example

      def project do
        [
          test_coverage: [
            tool: SonarQube.Coverage,
            sonar_xml: "reports/sonar-coverage.xml"
          ]
        ]
      end
  """

  @default_output "cover/sonar-coverage.xml"

  @enforce_keys [:covered, :files, :lines, :path, :percentage]
  defstruct [:covered, :files, :lines, :path, :percentage]

  @type t :: %__MODULE__{
          covered: non_neg_integer(),
          files: non_neg_integer(),
          lines: non_neg_integer(),
          path: String.t(),
          percentage: float()
        }

  @typep file_coverage :: {String.t(), [line_hit()]}
  @typep line_hit :: {non_neg_integer(), non_neg_integer()}

  @doc """
  Starts cover instrumentation. Called automatically by `mix test --cover`.

  Returns a callback that exports the SonarQube XML report and then
  runs the default cover reporting.
  """
  @spec start(Path.t(), Keyword.t()) :: (-> :ok)
  def start(compile_path, opts) do
    default_callback = apply(Mix.Tasks.Test.Cover, :start, [compile_path, opts])

    fn ->
      output_path = Keyword.get(opts, :sonar_xml, @default_output)

      case export(output: output_path) do
        {:ok, %__MODULE__{covered: cloc, lines: loc, percentage: pct, files: files, path: path}} ->
          Mix.shell().info("Covered #{cloc} of #{loc} lines (#{pct}%) across #{files} files.")
          Mix.shell().info("Report written to #{path}.")

        {:error, reason} ->
          Mix.shell().error(reason)
      end

      default_callback.()
    end
  end

  @doc """
  Exports the current `:cover` data to SonarQube XML.

  Call this when `:cover` is running and has data available.
  Useful for programmatic integration where you manage the cover
  lifecycle yourself.

  ## Options

    * `:output` - Output path for the XML file. Defaults to `"cover/sonar-coverage.xml"`.
  """
  @spec export(Keyword.t()) :: {:ok, t()} | {:error, String.t()}
  def export(opts \\ []) do
    output_path = Keyword.get(opts, :output, @default_output)

    case :cover.modules() do
      [] -> {:error, "No cover data available. Run tests with --cover first."}
      modules -> generate_report(modules, output_path)
    end
  catch
    :error, :undef ->
      {:error, "Cover is not running. Run tests with --cover first."}
  end

  @spec generate_report([module()], String.t()) :: {:ok, t()}
  defp generate_report(modules, output_path) do
    file_coverages =
      modules
      |> Enum.map(&analyze_module/1)
      |> Enum.reject(&is_nil/1)

    xml = build_xml(file_coverages)
    File.mkdir_p!(Path.dirname(output_path))
    File.write!(output_path, xml)

    total_lines = Enum.reduce(file_coverages, 0, fn {_, lines}, acc -> acc + length(lines) end)

    covered =
      Enum.reduce(file_coverages, 0, fn {_, lines}, acc ->
        acc + Enum.count(lines, fn {_, count} -> count > 0 end)
      end)

    percentage = if total_lines > 0, do: Float.round(covered / total_lines * 100, 1), else: 0.0

    {:ok,
     %__MODULE__{
       covered: covered,
       files: length(file_coverages),
       lines: total_lines,
       path: output_path,
       percentage: percentage
     }}
  end

  @spec analyze_module(module()) :: file_coverage() | nil
  defp analyze_module(module) do
    case :cover.analyse(module, :coverage, :line) do
      {:ok, line_data} ->
        source_file = find_source_file(module)

        if source_file do
          source_lines = read_source_lines(source_file)

          lines =
            line_data
            |> Enum.map(fn {{_mod, line}, {hits, _misses}} -> {line, hits} end)
            |> Enum.reject(fn {line, _} -> line == 0 end)
            |> Enum.reject(fn {line, _} -> non_executable_line?(source_lines, line) end)
            |> Enum.sort_by(&elem(&1, 0))

          {source_file, lines}
        end

      {:error, _} ->
        nil
    end
  end

  @spec find_source_file(module()) :: String.t() | nil
  defp find_source_file(module) do
    case module.module_info(:compile)[:source] do
      nil -> nil
      source -> source |> List.to_string() |> make_relative()
    end
  rescue
    _ -> nil
  end

  @spec read_source_lines(String.t()) :: [String.t()]
  defp read_source_lines(path) do
    case File.read(path) do
      {:ok, contents} -> String.split(contents, "\n")
      _ -> []
    end
  end

  @spec non_executable_line?([String.t()], non_neg_integer()) :: boolean()
  defp non_executable_line?(source_lines, line_num) do
    case Enum.at(source_lines, line_num - 1) do
      nil -> false
      line -> String.trim(line) == "end"
    end
  end

  @spec make_relative(String.t()) :: String.t()
  defp make_relative(path) do
    cwd = File.cwd!()

    if String.starts_with?(path, cwd) do
      String.trim_leading(path, cwd <> "/")
    else
      path
    end
  end

  @spec build_xml([file_coverage()]) :: String.t()
  defp build_xml(file_coverages) do
    files_xml =
      file_coverages
      |> Enum.map(fn {path, lines} ->
        lines_xml =
          lines
          |> Enum.map(fn {line, hits} ->
            covered = if hits > 0, do: "true", else: "false"
            ~s(    <lineToCover lineNumber="#{line}" covered="#{covered}"/>)
          end)
          |> Enum.join("\n")

        ~s(  <file path="#{escape_xml(path)}">\n#{lines_xml}\n  </file>)
      end)
      |> Enum.join("\n")

    ~s(<?xml version="1.0" encoding="UTF-8"?>\n<coverage version="1">\n#{files_xml}\n</coverage>\n)
  end

  @doc false
  @spec escape_xml(String.t()) :: String.t()
  def escape_xml(str) do
    str
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
  end
end
