# AI Self-Improvement Workflow

This reusable workflow provides AI-powered code analysis and improvement suggestions for any repository.

## Features

- 🔍 **Automated Code Analysis**: Static analysis, security scanning, complexity metrics
- 🧠 **AI-Powered Insights**: Intelligent improvement suggestions
- 🎯 **Multi-Language Support**: Auto-detects Elixir, Python, JavaScript, Go, Rust
- 📊 **Coverage Analysis**: Test coverage tracking and improvement suggestions
- 🐛 **Security Scanning**: Identifies security vulnerabilities
- 📝 **Automated Reports**: Generates detailed improvement reports
- ✅ **Issue Creation**: Optionally creates GitHub issues for improvements
- 🔧 **PR Generation**: Can create PRs with automated fixes

## Usage in Your Repository

### Basic Usage

Create a workflow file in your repository (e.g., `.github/workflows/ai-improve.yml`):

```yaml
name: Weekly AI Improvement

on:
  schedule:
    - cron: '0 0 * * 0'  # Weekly on Sunday
  workflow_dispatch:  # Manual trigger

jobs:
  improve:
    uses: jmanhype/req_llm_gateway/.github/workflows/ai-self-improve.yml@main
    secrets:
      ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
      GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Advanced Configuration

```yaml
name: AI Code Improvement

on:
  pull_request:
    types: [opened, synchronize]
  workflow_dispatch:

jobs:
  analyze-pr:
    uses: jmanhype/req_llm_gateway/.github/workflows/ai-self-improve.yml@main
    with:
      language: 'python'
      improvement_types: 'code-quality,security,tests,performance'
      create_issues: true
      create_pr: false
      target_branch: ${{ github.head_ref || github.ref_name }}
      ai_provider: 'anthropic'
    secrets:
      ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
      GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## Configuration Options

### Inputs

| Input | Description | Default | Required |
|-------|-------------|---------|----------|
| `language` | Primary programming language or 'auto-detect' | `auto-detect` | No |
| `improvement_types` | Comma-separated: code-quality,security,docs,tests,performance,refactor | `code-quality,security,docs,tests` | No |
| `create_issues` | Create GitHub issues for improvements | `true` | No |
| `create_pr` | Create PR with automated improvements | `false` | No |
| `target_branch` | Branch to analyze | `main` | No |
| `ai_provider` | AI provider: anthropic, openai, local | `anthropic` | No |

### Secrets

| Secret | Description | Required |
|--------|-------------|----------|
| `ANTHROPIC_API_KEY` | API key for Claude AI | Recommended |
| `OPENAI_API_KEY` | API key for OpenAI | Optional |
| `GH_TOKEN` | GitHub token with repo/issue permissions | Optional (uses default GITHUB_TOKEN) |

### Outputs

| Output | Description |
|--------|-------------|
| `improvements_found` | Number of improvements identified |
| `report_url` | URL to the detailed improvement report |

## Improvement Types

1. **code-quality**: Complexity analysis, maintainability metrics, code smells
2. **security**: Vulnerability scanning, security best practices
3. **docs**: Documentation completeness and quality
4. **tests**: Test coverage, missing test cases
5. **performance**: Performance bottlenecks and optimization opportunities
6. **refactor**: Refactoring suggestions for better code structure

## Setting Up API Keys

### For Anthropic (Claude)

1. Get your API key from https://console.anthropic.com/
2. Add to your repository secrets:
   - Go to Settings → Secrets and variables → Actions
   - Click "New repository secret"
   - Name: `ANTHROPIC_API_KEY`
   - Value: Your API key

### For OpenAI

1. Get your API key from https://platform.openai.com/
2. Add to repository secrets as `OPENAI_API_KEY`

## Example Workflows

### Daily Code Quality Check

```yaml
name: Daily Quality Check

on:
  schedule:
    - cron: '0 9 * * 1-5'  # Weekdays at 9 AM

jobs:
  quality:
    uses: jmanhype/req_llm_gateway/.github/workflows/ai-self-improve.yml@main
    with:
      improvement_types: 'code-quality,security'
      create_issues: true
    secrets:
      ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
```

### PR Review Assistant

```yaml
name: AI PR Review

on:
  pull_request:
    types: [opened, synchronize]

jobs:
  review:
    uses: jmanhype/req_llm_gateway/.github/workflows/ai-self-improve.yml@main
    with:
      create_issues: false
      create_pr: false
      target_branch: ${{ github.head_ref }}
    secrets:
      ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
```

### Monthly Deep Analysis

```yaml
name: Monthly Deep Dive

on:
  schedule:
    - cron: '0 0 1 * *'  # First day of each month

jobs:
  deep-analysis:
    uses: jmanhype/req_llm_gateway/.github/workflows/ai-self-improve.yml@main
    with:
      improvement_types: 'code-quality,security,docs,tests,performance,refactor'
      create_issues: true
      create_pr: true
    secrets:
      ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
      GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## Viewing Results

After the workflow runs:

1. **Workflow Summary**: Check the workflow run summary for key metrics
2. **Artifacts**: Download the `ai-improvement-analysis` artifact for detailed JSON results
3. **Issues**: Review created issues labeled with `ai-improvement`
4. **Pull Requests**: Review PRs with automated fixes (if enabled)

## Best Practices

1. **Start with Analysis Only**: Set `create_issues: false` and `create_pr: false` initially
2. **Review Findings**: Check the artifacts to understand improvement suggestions
3. **Enable Gradually**: Turn on issue creation once confident in results
4. **Use on Specific Branches**: Target feature branches for focused improvements
5. **Combine with CI**: Run as part of your existing CI/CD pipeline
6. **API Rate Limits**: Be mindful of API costs and rate limits

## Limitations

- AI suggestions should be reviewed by humans before implementation
- Some language-specific tools may require additional setup
- API keys required for AI-powered analysis
- Large repositories may take longer to analyze

## Support

For issues or questions about this workflow:
- Open an issue in the [req_llm_gateway](https://github.com/jmanhype/req_llm_gateway) repository
- Check existing issues for similar problems
- Review the workflow logs for debugging information

## License

This workflow is provided as part of the req_llm_gateway project.
