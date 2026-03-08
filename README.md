# Mix SonarQube

> Mix utilities for the sonar-elixir SonarQube plugin.

[![CI](https://github.com/hpopp/mix-sonarqube/actions/workflows/ci.yml/badge.svg)](https://github.com/hpopp/mix-sonarqube/actions/workflows/ci.yml)
[![Quality Gate Status](https://sonarqube.hpopp.dev/api/project_badges/measure?project=mix-sonarqube&metric=alert_status&token=sqb_0a501102bdef334017355dc7da9618af68397081)](https://sonarqube.hpopp.dev/dashboard?id=mix-sonarqube)
[![Hex.pm](https://img.shields.io/hexpm/v/sonarqube.svg)](https://hex.pm/packages/sonarqube)
[![License](https://img.shields.io/github/license/hpopp/mix-sonarqube)](LICENSE)
[![Last Updated](https://img.shields.io/github/last-commit/hpopp/mix-sonarqube.svg)](https://github.com/hpopp/mix-sonarqube/commits/main)

> [!NOTE]
> Mix tasks in this package are meant to be run before `sonar-scanner` to support features like test
> coverage reporting. You also need the [sonar-elixir](https://github.com/hpopp/sonar-elixir) plugin installed
> in your SonarQube instance for Elixir language support.

## Installation

Add `sonarqube` to your list of dependencies and configure it as the cover tool in `mix.exs`:

```elixir
def project do
  [
    app: :your_app,
    deps: deps(),
    version: "0.1.0",
    # Add this.
    test_coverage: [tool: SonarQube.Coverage]
  ]
end

# Add this so `mix sonarqube.coverage` runs in the test environment.
def cli do
  [preferred_envs: ["sonarqube.coverage": :test]]
end

def deps do
  [
    {:sonarqube, "~> 0.1.0", only: [:dev, :test], runtime: false}
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

Then run `sonar-scanner` to upload the results to your SonarQube instance.

## License

Copyright (c) 2026 Henry Popp

This project is MIT licensed. See the [LICENSE](LICENSE) for details.
