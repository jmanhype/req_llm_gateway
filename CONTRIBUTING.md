# Contributing to ReqLLMGateway

Thank you for your interest in contributing to ReqLLMGateway! This guide will help you get started.

## Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help create a welcoming environment for all contributors

## Getting Started

### Prerequisites

- Elixir 1.14 or later
- Erlang/OTP 25 or later
- Git

### Setup Development Environment

1. Fork and clone the repository:

```bash
git clone https://github.com/YOUR_USERNAME/recllmgateway.git
cd recllmgateway
```

2. Install dependencies:

```bash
mix deps.get
```

3. Set up environment variables:

```bash
export OPENAI_API_KEY="your-test-key"
export ANTHROPIC_API_KEY="your-test-key"
```

4. Run tests:

```bash
mix test
```

## Development Workflow

### Running Tests

```bash
# Run all tests
mix test

# Run specific test file
mix test test/rec_llm_gateway/plug_test.exs

# Run with coverage
mix coveralls

# Run with HTML coverage report
mix coveralls.html
```

### Code Quality

Before submitting a PR, ensure your code passes all quality checks:

```bash
# Run all quality checks
mix quality

# Or run individually:
mix format --check-formatted  # Check formatting
mix credo --strict             # Static analysis
mix dialyzer                   # Type checking
```

Auto-fix formatting issues:

```bash
mix format
```

### Running the Gateway Locally

Since this is a library, you'll need to test it in a Phoenix app or standalone:

```bash
# In a Phoenix app
cd path/to/phoenix/app
# Add {:rec_llm_gateway, path: "../recllmgateway"} to mix.exs
mix deps.get
mix phx.server
```

## Making Changes

### Branch Naming

Use descriptive branch names:

- `feature/add-streaming-support`
- `fix/handle-timeout-errors`
- `docs/improve-getting-started`
- `refactor/simplify-pricing-logic`

### Commit Messages

Write clear, concise commit messages:

```
Add streaming support for chat completions

- Implement Server-Sent Events (SSE) for streaming
- Add tests for streaming responses
- Update documentation with streaming examples

Closes #123
```

Format:
- First line: Summary (50 chars or less)
- Blank line
- Detailed explanation (wrap at 72 chars)
- Reference issues/PRs

### Writing Tests

All new features must include tests:

```elixir
defmodule ReqLLMGateway.NewFeatureTest do
  use ExUnit.Case, async: true
  import Mox

  setup :verify_on_exit!

  describe "new_feature/1" do
    test "handles successful case" do
      # Arrange
      input = %{...}

      # Act
      result = ReqLLMGateway.new_feature(input)

      # Assert
      assert result == expected
    end

    test "handles error case" do
      # ...
    end
  end
end
```

### Documentation

Update documentation when adding features:

1. **Module docs**: Add `@moduledoc` and `@doc` to new modules/functions
2. **Guides**: Update or create guides in `docs/guides/`
3. **README**: Update if adding user-facing features
4. **CHANGELOG**: Add entry under `[Unreleased]`

## Pull Request Process

### Before Submitting

1. ✅ Tests pass: `mix test`
2. ✅ Quality checks pass: `mix quality`
3. ✅ Documentation is updated
4. ✅ CHANGELOG.md is updated

### Submitting

1. Push your branch to your fork
2. Create a Pull Request to `main`
3. Fill out the PR template:
   - **Summary**: What does this PR do?
   - **Changes**: Bullet points of key changes
   - **Testing**: How was this tested?
   - **Screenshots**: If applicable
   - **Breaking Changes**: If any

### PR Template

```markdown
## Summary
Brief description of changes

## Changes
- Added feature X
- Fixed bug Y
- Updated docs for Z

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests pass
- [ ] Manually tested with Phoenix app

## Breaking Changes
None / List breaking changes

## Checklist
- [ ] Tests pass (`mix test`)
- [ ] Quality checks pass (`mix quality`)
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
```

### Review Process

- Maintainers will review your PR
- Address feedback by pushing new commits
- Once approved, maintainers will merge

## Adding New Providers

To add support for a new LLM provider:

1. **Update LLMClient**:

```elixir
defp call_provider("new_provider", request, api_key) do
  # Implementation
end
```

2. **Add Pricing**:

```elixir
defp pricing_for("new_provider", "model-name") do
  %{
    prompt_tokens: Decimal.new("0.001"),
    completion_tokens: Decimal.new("0.002")
  }
end
```

3. **Add Tests**:

```elixir
test "handles new_provider requests" do
  # ...
end
```

4. **Update Documentation**:
   - Add to `docs/guides/multi_provider.md`
   - Update README examples

## Reporting Issues

### Bug Reports

Include:
- Elixir/OTP versions
- ReqLLMGateway version
- Steps to reproduce
- Expected vs actual behavior
- Error messages/stack traces

### Feature Requests

Include:
- Use case description
- Proposed solution
- Alternative solutions considered
- Willingness to contribute

## Questions?

- Open a [Discussion](https://github.com/jmanhype/recllmgateway/discussions)
- Ask in issues with `question` label

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
