[![Hex.pm](https://img.shields.io/hexpm/v/sonarqube.svg)](https://hex.pm/packages/sonarqube)
[![License](https://img.shields.io/github/license/hpopp/mix-sonarqube)](LICENSE)
[![Last Updated](https://img.shields.io/github/last-commit/hpopp/mix-sonarqube.svg)](https://github.com/hpopp/mix-sonarqube/commits/main)

# SonarQube

SonarQube integration tools for Elixir projects. Converts Elixir test coverage data into formats that SonarQube can import.

**Note:** You also need the [sonar-elixir](https://github.com/hpopp/sonar-elixir) plugin installed in your
SonarQube instance for Elixir language support.

## Installation

Add `sonarqube` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:sonarqube, "~> 0.1.0", only: [:dev, :test], runtime: false}
  ]
end
```

Then configure it as the cover tool:

```elixir
def project do
  [
    test_coverage: [tool: SonarQube.Coverage]
  ]
end
```

## Usage

Run tests with coverage and generate a SonarQube-compatible XML report:

```bash
mix sonarqube.coverage
```

This produces `cover/sonar-coverage.xml` alongside the standard Elixir coverage output.
All arguments are passed through to `mix test`:

```bash
mix sonarqube.coverage test/my_module_test.exs
```

### Options

Options are configured via `test_coverage` in `mix.exs`:

| Option       | Default                    | Description                    |
| ------------ | -------------------------- | ------------------------------ |
| `:sonar_xml` | `cover/sonar-coverage.xml` | Output path for the XML report |

```elixir
test_coverage: [tool: SonarQube.Coverage, sonar_xml: "reports/sonar-coverage.xml"]
```

### SonarQube Configuration

Add the coverage report path to your `sonar-project.properties`:

```properties
sonar.coverageReportPaths=cover/sonar-coverage.xml
```

## License

Copyright (c) 2026 Henry Popp

This project is MIT licensed. See the [LICENSE](LICENSE) for details.
