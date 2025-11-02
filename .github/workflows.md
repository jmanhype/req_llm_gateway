# GitHub Actions Workflows

This directory should contain CI/CD workflows, but GitHub App permissions prevent
automatic creation of workflow files.

## Required Workflow: ci.yml

To add the CI/CD workflow, create `.github/workflows/ci.yml` with the following content:

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    name: Test (Elixir ${{matrix.elixir}} / OTP ${{matrix.otp}})
    runs-on: ubuntu-latest
    strategy:
      matrix:
        elixir: ['1.14', '1.15', '1.16']
        otp: ['25', '26']
        exclude:
          - elixir: '1.14'
            otp: '26'

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Elixir
        uses: erlef/setup-beam@v1
        with:
          elixir-version: ${{matrix.elixir}}
          otp-version: ${{matrix.otp}}

      - name: Restore dependencies cache
        uses: actions/cache@v3
        with:
          path: |
            deps
            _build
          key: ${{ runner.os }}-mix-${{ matrix.otp }}-${{ matrix.elixir }}-${{ hashFiles('**/mix.lock') }}
          restore-keys: |
            ${{ runner.os }}-mix-${{ matrix.otp }}-${{ matrix.elixir }}-

      - name: Install dependencies
        run: mix deps.get

      - name: Compile code (warnings as errors)
        run: mix compile --warnings-as-errors

      - name: Run tests
        run: mix test

  quality:
    name: Code Quality
    runs-on: ubuntu-latest
    env:
      MIX_ENV: test

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Elixir
        uses: erlef/setup-beam@v1
        with:
          elixir-version: '1.16'
          otp-version: '26'

      - name: Restore dependencies cache
        uses: actions/cache@v3
        with:
          path: |
            deps
            _build
          key: ${{ runner.os }}-mix-quality-${{ hashFiles('**/mix.lock') }}
          restore-keys: |
            ${{ runner.os }}-mix-quality-

      - name: Install dependencies
        run: mix deps.get

      - name: Check formatting
        run: mix format --check-formatted

      - name: Run Credo
        run: mix credo --strict

      - name: Restore PLT cache
        uses: actions/cache@v3
        id: plt-cache
        with:
          path: priv/plts
          key: ${{ runner.os }}-plt-${{ hashFiles('**/mix.lock') }}
          restore-keys: |
            ${{ runner.os }}-plt-

      - name: Create PLTs
        if: steps.plt-cache.outputs.cache-hit != 'true'
        run: mix dialyzer --plt

      - name: Run Dialyzer
        run: mix dialyzer --format github

  coverage:
    name: Test Coverage
    runs-on: ubuntu-latest
    env:
      MIX_ENV: test

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Elixir
        uses: erlef/setup-beam@v1
        with:
          elixir-version: '1.16'
          otp-version: '26'

      - name: Restore dependencies cache
        uses: actions/cache@v3
        with:
          path: |
            deps
            _build
          key: ${{ runner.os }}-mix-coverage-${{ hashFiles('**/mix.lock') }}
          restore-keys: |
            ${{ runner.os }}-mix-coverage-

      - name: Install dependencies
        run: mix deps.get

      - name: Run tests with coverage
        run: mix coveralls.github
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## Manual Setup

1. Navigate to `.github/workflows/` directory
2. Create `ci.yml` with the content above
3. Commit and push manually by a user with repository admin access
