defmodule SonarQube.CoverageTest do
  use ExUnit.Case, async: false

  setup do
    output_dir =
      Path.join(System.tmp_dir!(), "sonarqube_test_#{System.unique_integer([:positive])}")

    File.mkdir_p!(output_dir)
    output_path = Path.join(output_dir, "coverage.xml")

    on_exit(fn -> File.rm_rf!(output_dir) end)

    %{output_path: output_path, output_dir: output_dir}
  end

  describe "export/1" do
    test "exports cover data to XML", %{output_path: output_path} do
      ensure_cover()

      {:ok, result} = SonarQube.Coverage.export(output: output_path)

      assert result.files > 0
      assert result.lines > 0
      assert result.covered >= 0
      assert result.percentage >= 0.0
      assert result.path == output_path

      xml = File.read!(output_path)
      assert xml =~ ~s(<?xml version="1.0" encoding="UTF-8"?>)
      assert xml =~ "<coverage version=\"1\">"
      assert xml =~ "<lineToCover"
    end

    test "creates output directory if missing", %{output_dir: output_dir} do
      nested_path = Path.join([output_dir, "nested", "dir", "coverage.xml"])
      ensure_cover()

      {:ok, _result} = SonarQube.Coverage.export(output: nested_path)

      assert File.exists?(nested_path)
    end

    test "result contains correct stats", %{output_path: output_path} do
      ensure_cover()

      {:ok, %SonarQube.Coverage{} = result} = SonarQube.Coverage.export(output: output_path)

      assert is_integer(result.files)
      assert is_integer(result.lines)
      assert is_integer(result.covered)
      assert is_float(result.percentage)
      assert result.percentage >= 0.0 and result.percentage <= 100.0
    end
  end

  describe "XML output format" do
    test "produces valid SonarQube XML structure", %{output_path: output_path} do
      ensure_cover()
      {:ok, _result} = SonarQube.Coverage.export(output: output_path)

      xml = File.read!(output_path)
      assert xml =~ ~r/<file path="[^"]+">.*<\/file>/s
      assert xml =~ ~r/<lineToCover lineNumber="\d+" covered="(true|false)"\/>/
    end

    test "escapes XML special characters in paths" do
      assert SonarQube.Coverage.escape_xml("lib/foo&bar<baz>.ex") ==
               "lib/foo&amp;bar&lt;baz&gt;.ex"
    end

    test "escapes quotes in paths" do
      assert SonarQube.Coverage.escape_xml(~s(lib/"quoted".ex)) ==
               "lib/&quot;quoted&quot;.ex"
    end
  end

  defp ensure_cover do
    case :cover.start() do
      {:ok, _pid} ->
        ebin_dir = Path.join([Mix.Project.build_path(), "lib", "sonarqube", "ebin"])
        :cover.compile_beam_directory(String.to_charlist(ebin_dir))

      {:error, {:already_started, _pid}} ->
        :ok
    end

    SonarQube.Coverage.escape_xml("test&value")
  end
end
