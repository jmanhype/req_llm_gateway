# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- **BREAKING**: Replaced custom HTTP client with ReqLLM integration
  - Now supports 45+ LLM providers (OpenAI, Anthropic, Google, Groq, AWS Bedrock, etc.)
  - API key configuration moved to ReqLLM (`:req_llm` config namespace)
  - Automatic cost calculation and model registry (665+ models)
  - Production-grade streaming support with HTTP/2
- Updated all documentation to reflect ReqLLM usage
- Simplified LLMClient module to be a thin wrapper around ReqLLM

### Added
- ReqLLM dependency (~> 1.0.0-rc.6) for multi-provider support
- Support for 45+ providers beyond OpenAI and Anthropic
- Automatic token counting and cost calculation via ReqLLM
- Professional project structure with quality tools
- Comprehensive documentation guides (5 guides, 2,175+ lines)
- CI/CD workflow documentation
- Code quality tools (Credo, Dialyzer, ExCoveralls)
- Example applications (Phoenix, standalone with Docker/K8s)
- Contributing guidelines (CONTRIBUTING.md)
- Test support infrastructure (ConnCase, mocks)

### Removed
- HTTPoison dependency (replaced by ReqLLM's Req-based client)
- Custom provider HTTP implementations (now handled by ReqLLM)

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
