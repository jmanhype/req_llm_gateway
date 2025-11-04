# 🤖 AI Self-Improvement Automation System

[![CI Status](https://github.com/jmanhype/req_llm_gateway/workflows/CI/badge.svg)](https://github.com/jmanhype/req_llm_gateway/actions/workflows/ci.yml)
[![Quality](https://github.com/jmanhype/req_llm_gateway/workflows/Quality%20Improvement/badge.svg)](https://github.com/jmanhype/req_llm_gateway/actions/workflows/quality-improvement.yml)
[![Security](https://github.com/jmanhype/req_llm_gateway/workflows/Security%20%26%20Dependencies/badge.svg)](https://github.com/jmanhype/req_llm_gateway/actions/workflows/security.yml)

## Overview

This repository includes a comprehensive AI-powered automation system that continuously improves code quality, security, and maintainability. The system runs automatically and provides actionable insights through GitHub issues, PR comments, and detailed reports.

## 🚀 Quick Start

**New to automation?** → Read the [Quick Start Guide](docs/guides/automation-quick-start.md)

**Want details?** → Read the [Complete Documentation](docs/guides/automation.md)

## ✨ Features

### 🔄 Continuous Integration & Deployment
- **Multi-version testing** across Elixir 1.14-1.16 and OTP 25-26
- **Code quality checks** with Credo, Dialyzer, and formatting
- **Test coverage tracking** with automated thresholds
- **Security scanning** for vulnerabilities

### 🤖 AI-Powered Code Review
- **Automated PR reviews** with intelligent suggestions
- **Complexity analysis** and code smell detection
- **Best practices recommendations**
- **Pattern analysis** for Elixir idioms

### 📊 Quality Improvement
- **Weekly quality reports** with prioritized improvements
- **Test coverage analysis** identifying gaps
- **Documentation coverage tracking**
- **Performance optimization suggestions**
- **Automated issue creation** for tracking

### 🔒 Security & Dependency Management
- **Daily vulnerability scans** of dependencies
- **Automated security alerts** for critical issues
- **License compliance checking**
- **Retired package detection**
- **Dependabot integration** for updates

### 📚 Documentation Automation
- **Auto-generated API docs** via ExDoc
- **GitHub Pages deployment**
- **Documentation quality checks**
- **Changelog reminders** on PRs
- **Link validation**

### 📈 Self-Improvement Reporting
- **Comprehensive metrics collection**
- **Trend analysis** over time
- **Success tracking** against targets
- **Automated improvement plans**
- **Weekly summary issues**

## 📅 Automation Schedule

| Workflow | Frequency | Purpose |
|----------|-----------|---------|
| CI/CD | On push/PR | Test and validate changes |
| AI Code Review | On PR | Intelligent code review |
| Quality Improvement | Weekly (Mon 9:00 UTC) | Identify improvements |
| Security Scan | Daily (2:00 UTC) | Monitor vulnerabilities |
| Documentation | On doc changes | Keep docs updated |
| Self-Improvement | Weekly (Mon 10:00 UTC) | Track progress |

## 🎯 What Gets Automated

### ✅ Automatically Done For You

- Test execution across multiple versions
- Code formatting verification
- Static analysis (Credo)
- Type checking (Dialyzer)
- Coverage calculation and reporting
- Security vulnerability scanning
- Dependency update PRs
- Documentation generation
- Quality metric collection
- Improvement suggestions
- Issue creation for action items
- PR review comments

### 👀 Requires Human Review

- Merging PRs (even if all checks pass)
- Prioritizing improvements
- Architecture decisions
- Breaking changes
- Security policy decisions

## 📊 Metrics Tracked

The system automatically tracks and reports on:

- **Code Coverage** (target: >85%)
- **Documentation Coverage** (target: >95%)
- **Code Quality Score** (target: >90%)
- **Security Vulnerabilities** (target: 0)
- **Test-to-Code Ratio**
- **Module Count and Size**
- **Complexity Indicators**
- **TODO/FIXME Comments**
- **Long Functions (>50 lines)**
- **Dependency Health**

## 🛠️ Local Tools

Run analysis locally anytime:

```bash
# Comprehensive quality analysis
./scripts/analyze_code_quality.sh

# Generate improvement suggestions
./scripts/generate_improvement_suggestions.sh

# Collect metrics
./scripts/metrics_collector.exs

# Standard Elixir quality tools
mix test --cover
mix credo --strict
mix dialyzer
mix format --check-formatted
```

## 📖 Documentation

- **[Quick Start Guide](docs/guides/automation-quick-start.md)** - Get started in 5 minutes
- **[Complete Documentation](docs/guides/automation.md)** - Comprehensive guide
- **[Workflow Reference](.github/workflows/)** - Individual workflow docs

## 🔧 Configuration

### Dependabot

Configuration: `.github/dependabot.yml`

**Update Schedule:**
- **Mix dependencies:** Weekly (Mondays, 9:00 UTC)
- **GitHub Actions:** Weekly (Tuesdays, 9:00 UTC)
- **NPM packages:** Weekly (Wednesdays, 9:00 UTC)
- **Dev Containers:** Monthly

### CI Thresholds

**Coverage Threshold:** 80% (configurable in `.github/workflows/ci.yml`)

**Code Quality:** Strict mode (configurable in `.credo.exs`)

## 📦 Components

### GitHub Actions Workflows

Located in `.github/workflows/`:

1. **`ci.yml`** - Comprehensive CI/CD pipeline
2. **`ai-code-review.yml`** - AI-powered code review
3. **`quality-improvement.yml`** - Quality analysis and suggestions
4. **`security.yml`** - Security and dependency scanning
5. **`documentation.yml`** - Documentation generation
6. **`self-improvement-report.yml`** - Weekly progress tracking

### Helper Scripts

Located in `scripts/`:

1. **`analyze_code_quality.sh`** - Comprehensive quality analysis
2. **`generate_improvement_suggestions.sh`** - AI suggestions generator
3. **`metrics_collector.exs`** - Metrics collection and storage

### Reports & Artifacts

The system generates various reports:

- **Quality summaries** (coverage, metrics, issues)
- **Improvement suggestions** (prioritized action items)
- **Security reports** (vulnerabilities, compliance)
- **Documentation reports** (coverage, quality)
- **Metrics history** (trend data)

Access via:
- GitHub Actions artifacts
- Automated GitHub issues
- PR comments

## 🎨 Customization

### Modify Workflow Triggers

Edit workflow files in `.github/workflows/`:

```yaml
on:
  schedule:
    - cron: '0 9 * * 1'  # Your preferred schedule
  workflow_dispatch:     # Keep for manual runs
```

### Adjust Quality Thresholds

**Coverage threshold** in `.github/workflows/ci.yml`:
```yaml
if (( $(echo "$COVERAGE < 80" | bc -l) )); then
  # Change 80 to your target
```

**Credo strictness** in `.credo.exs`:
```elixir
checks: [
  {Credo.Check.Design.TagTODO, exit_status: 0},  # Adjust as needed
  # ... more checks
]
```

### Add Custom Checks

Create new scripts in `scripts/` or add jobs to workflows:

```yaml
custom_check:
  name: Custom Check
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - name: Run custom check
      run: ./scripts/your_custom_script.sh
```

## 🐛 Troubleshooting

### Common Issues

**Workflows not running?**
- Check that GitHub Actions is enabled
- Verify workflow syntax with `actionlint` (if available)
- Check repository settings → Actions

**No reports being generated?**
- Verify workflow permissions (contents: write, issues: write)
- Check workflow logs for errors
- Ensure scripts are executable (`chmod +x scripts/*.sh`)

**Dependabot not creating PRs?**
- Check `.github/dependabot.yml` syntax
- Visit Insights → Dependency graph → Dependabot
- Ensure mix.lock is committed

### Getting Help

1. **Check workflow logs** in Actions tab
2. **Run scripts locally** to debug
3. **Review documentation** in `docs/guides/`
4. **Open an issue** with the `automation` label

## 📈 Success Indicators

After one month, you should see:

- ✅ Automated issues tracking improvements
- ✅ Regular dependency updates being merged
- ✅ Coverage remaining stable or increasing
- ✅ Security vulnerabilities addressed quickly
- ✅ Documentation coverage improving
- ✅ Code quality metrics trending upward
- ✅ Team using insights for planning

## 🤝 Contributing to Automation

Improvements to the automation system are welcome!

**To contribute:**
1. Test changes locally first
2. Update documentation
3. Add comments to explain logic
4. Test with manual workflow triggers
5. Submit PR with changes

## 📚 Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Dependabot Configuration](https://docs.github.com/en/code-security/dependabot)
- [Elixir Testing Best Practices](https://hexdocs.pm/ex_unit/ExUnit.html)
- [Credo Documentation](https://hexdocs.pm/credo/overview.html)
- [ExCoveralls Guide](https://hexdocs.pm/excoveralls/)

## 📄 License

This automation system is part of ReqLLMGateway and is released under the same MIT License.

## 🙏 Acknowledgments

This automation system uses:
- GitHub Actions for workflow automation
- Dependabot for dependency management
- Credo for code analysis
- Dialyzer for type checking
- ExCoveralls for coverage reporting
- ExDoc for documentation generation

---

**Questions?** See the [Quick Start Guide](docs/guides/automation-quick-start.md) or open an issue.

**Want to customize?** See the [Complete Documentation](docs/guides/automation.md).

**Happy automating! 🚀**
