defmodule SonarQube.MixProject do
  use Mix.Project

  @source_url "https://github.com/hpopp/mix-sonarqube"
  @version "0.1.0"

  def project do
    [
      app: :sonarqube,
      cli: cli(),
      deps: deps(),
      description: "Mix utilities for the sonar-elixir SonarQube plugin.",
      docs: docs(),
      elixir: "~> 1.14",
      name: "SonarQube",
      package: package(),
      source_url: @source_url,
      start_permanent: Mix.env() == :prod,
      test_coverage: test_coverage(),
      version: @version
    ]
  end

  def cli do
    [preferred_envs: ["sonarqube.coverage": :test]]
  end

  defp test_coverage do
    [tool: SonarQube.Coverage]
  end

  def application do
    [
      extra_applications: [:logger, :tools]
    ]
  end

  defp deps do
    [
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.35", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      extras: ["README.md", "CHANGELOG.md", "LICENSE"],
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url
    ]
  end

  defp package do
    [
      files: ~w(lib mix.exs README.md LICENSE CHANGELOG.md),
      licenses: ["MIT"],
      links: %{
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md",
        "GitHub" => @source_url,
        "SonarQube Plugin" => "https://github.com/hpopp/sonar-elixir"
      },
      maintainers: ["Henry Popp"]
    ]
  end
end
