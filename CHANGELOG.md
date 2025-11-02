# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **ReqLLM integration**: 45+ providers with 665+ models
- Support for OpenAI, Anthropic, Google, Groq, xAI, Cerebras, and 35+ more providers
- Automatic cost calculation via ReqLLM's model registry
- HTTP/2 streaming support (via ReqLLM)
- Enhanced token counting and usage tracking
- Initial project setup with professional structure
- Comprehensive documentation guides
- CI/CD workflow with GitHub Actions
- Code quality tools (Credo, Dialyzer, ExCoveralls)
- Example applications (Phoenix, standalone)
- Contributing guidelines

### Changed
- **BREAKING**: Replaced HTTPoison with ReqLLM for multi-provider support
- **BREAKING**: Configuration format changed from `config :rec_llm_gateway, :api_keys` to ReqLLM's format
- LLMClient module refactored to use ReqLLM's `generate_text/3` function
- Documentation updated to reflect ReqLLM integration

### Migration Guide

**Old configuration (no longer works):**
```elixir
config :rec_llm_gateway,
  api_keys: %{
    "openai" => System.get_env("OPENAI_API_KEY"),
    "anthropic" => System.get_env("ANTHROPIC_API_KEY")
  }
```

**New configuration (ReqLLM):**
```bash
# Method 1: Environment variables (automatic)
export OPENAI_API_KEY="sk-..."
export ANTHROPIC_API_KEY="sk-ant-..."
```

Or:

```elixir
# Method 2: Explicit config
config :req_llm,
  openai_api_key: System.get_env("OPENAI_API_KEY"),
  anthropic_api_key: System.get_env("ANTHROPIC_API_KEY")
```

**What you gain:**
- 45+ providers instead of 2
- 665+ models in the registry
- Automatic cost calculation
- Better error handling
- HTTP/2 streaming support
- Model metadata and validation

## [0.1.0] - 2025-11-02

### Added
- OpenAI-compatible HTTP endpoint (`POST /v1/chat/completions`)
- Multi-provider routing (OpenAI, Anthropic)
- Model parser with `provider:model` syntax
- Built-in telemetry events
- ETS-backed usage tracking
- Cost calculation per provider/model
- Phoenix LiveDashboard integration
- Comprehensive test suite
- Configuration system with environment variables
- Support for custom LLM clients (testing)

### Core Modules
- `RecLLMGateway.Plug` - Main HTTP endpoint handler
- `RecLLMGateway.LLMClient` - Multi-provider client
- `RecLLMGateway.ModelParser` - Provider:model parser
- `RecLLMGateway.Pricing` - Cost calculation
- `RecLLMGateway.Usage` - Usage statistics tracking
- `RecLLMGateway.Telemetry` - Telemetry event definitions
- `RecLLMGateway.LiveDashboard` - LiveDashboard page
- `RecLLMGateway.Application` - OTP application

### Documentation
- Quick start guide
- Installation instructions
- Configuration options
- API examples (curl, Python, JavaScript)

### Known Limitations
- No streaming support (`stream: true` returns error)
- No persistence (usage data is in-memory)
- No rate limiting (requires external proxy)

[Unreleased]: https://github.com/jmanhype/recllmgateway/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/jmanhype/recllmgateway/releases/tag/v0.1.0
