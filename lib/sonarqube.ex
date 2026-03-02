defmodule SonarQube do
  @moduledoc """
  SonarQube integration tools for Elixir projects.

  Provides a cover tool and Mix tasks for converting Elixir test coverage
  data into formats compatible with SonarQube analysis.

  ## Setup

  Configure `SonarQube.Coverage` as the cover tool in your `mix.exs`:

      def project do
        [
          test_coverage: [tool: SonarQube.Coverage]
        ]
      end

  Then run `mix test --cover` or `mix sonarqube.coverage` to generate
  the SonarQube XML report.
  """
end
