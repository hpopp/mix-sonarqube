defmodule Mix.Tasks.Sonarqube.Coverage do
  @shortdoc "Run tests with coverage and export SonarQube XML report"

  @moduledoc """
  Runs `mix test --cover` to generate a SonarQube coverage report.

  Requires `test_coverage: [tool: SonarQube.Coverage]` in your `mix.exs`.

  All arguments are passed through to `mix test`.

  ## Examples

      $ mix sonarqube.coverage
      $ mix sonarqube.coverage --only integration
      $ mix sonarqube.coverage test/my_test.exs

  The output file can be imported into SonarQube by setting
  `sonar.coverageReportPaths` in your `sonar-project.properties`.
  """

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("test", ["--cover" | args])
  end
end
