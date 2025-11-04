# Automation Quick Start Guide

Get started with the AI Self-Improvement Automation System in 5 minutes!

## Prerequisites

- ✅ Git repository on GitHub
- ✅ Elixir project with tests
- ✅ GitHub Actions enabled

## Setup Steps

### 1. Enable GitHub Actions (2 minutes)

The workflows are already committed. GitHub will automatically detect and enable them.

**Verify:**
```bash
# Check if workflows exist
ls -la .github/workflows/

# Expected output:
# - ci.yml
# - ai-code-review.yml
# - quality-improvement.yml
# - security.yml
# - documentation.yml
# - self-improvement-report.yml
```

### 2. Configure Dependabot (1 minute)

Dependabot is already configured in `.github/dependabot.yml`.

**What it does:**
- Monitors dependencies for updates
- Creates automated PRs for updates
- Runs weekly for Mix, GitHub Actions, and NPM

**No action needed!** It will start working automatically.

### 3. Run First Analysis (2 minutes)

**Option A: Via GitHub Actions (Recommended)**
1. Go to your repository on GitHub
2. Click "Actions" tab
3. Select "CI" workflow
4. Click "Run workflow"
5. Wait ~3-5 minutes
6. Review results

**Option B: Locally**
```bash
# Run quality analysis
./scripts/analyze_code_quality.sh

# Generate improvement suggestions
./scripts/generate_improvement_suggestions.sh

# Collect metrics
./scripts/metrics_collector.exs
```

## What Happens Next?

### Immediate (On Every Push/PR)

✅ **Automated Testing**
- Tests run across multiple Elixir/OTP versions
- Code quality checks (Credo, formatting)
- Coverage analysis
- Security scans

✅ **AI Code Review** (on PRs)
- Automated review comments
- Complexity analysis
- Best practice suggestions

### Daily

✅ **Security Monitoring**
- Dependency vulnerability scans
- Outdated package detection
- Automated alerts

### Weekly

✅ **Quality Improvement Reports** (Mondays, 9:00 UTC)
- Comprehensive analysis
- Prioritized improvement suggestions
- Automated GitHub issue created

✅ **Self-Improvement Report** (Mondays, 10:00 UTC)
- Metrics collection
- Trend analysis
- Success tracking

✅ **Dependency Updates** (Various days)
- Mix: Mondays
- GitHub Actions: Tuesdays
- NPM: Wednesdays

## Understanding Your First Report

After running CI for the first time, you'll see:

### Green ✅ = Passing
- All tests pass
- Code is well-formatted
- No critical issues
- Coverage meets threshold

### Yellow ⚠️ = Warnings
- Coverage below target
- Documentation gaps
- Minor code quality issues
- Consider addressing

### Red ❌ = Failing
- Tests failing
- Critical security issues
- Major code problems
- **Must fix before merge**

## Quick Actions

### View Latest Reports

```bash
# Via GitHub CLI
gh run list --workflow=ci.yml --limit 5
gh run view --log

# Download artifacts
gh run download <run-id>
```

### Check Workflow Status

```bash
# List all workflows
gh workflow list

# View specific workflow
gh workflow view ci.yml
```

### Trigger Workflows Manually

```bash
# Run CI
gh workflow run ci.yml

# Run quality improvement
gh workflow run quality-improvement.yml

# Run security scan
gh workflow run security.yml
```

## Reading Your First Issue

The automation system will create GitHub issues automatically. Here's how to read them:

### Quality Improvement Issue

```markdown
Title: 🚀 Quality Improvement Report - 2024-XX-XX

Content:
- [ ] High Priority items (do this week)
- [ ] Medium Priority items (do this sprint)
- [ ] Low Priority items (continuous improvement)
```

**What to do:**
1. Review with your team
2. Create tasks for high-priority items
3. Schedule medium-priority items
4. Track low-priority items for future sprints

### Security Issue

```markdown
Title: 🚨 Security Vulnerabilities Detected

Content:
- Severity: High/Medium/Low
- Affected packages
- Recommendations
```

**What to do:**
1. **High severity:** Address immediately
2. **Medium severity:** Schedule for current sprint
3. **Low severity:** Monitor and plan update

## Customization Tips

### Adjust Report Frequency

Edit `.github/workflows/quality-improvement.yml`:
```yaml
schedule:
  - cron: '0 9 * * 1'  # Change to your preferred time
  # Format: minute hour day-of-month month day-of-week
  # Example: '0 14 * * 3' = Wednesdays at 2 PM UTC
```

### Change Coverage Threshold

Edit `.github/workflows/ci.yml`:
```yaml
if (( $(echo "$COVERAGE < 80" | bc -l) )); then
  # Change 80 to your desired percentage
```

### Add Team Reviewers

Edit `.github/dependabot.yml`:
```yaml
reviewers:
  - "your-github-username"
  - "teammate-username"
```

## Common First-Time Questions

### Q: Do I need to do anything for this to work?
**A:** No! Just push code and the automation runs automatically.

### Q: Will it create too many issues?
**A:** No. Issues are created weekly and consolidated into single issues with updates.

### Q: Can I disable certain checks?
**A:** Yes. Remove or comment out jobs in the workflow files, or disable specific workflows in GitHub Settings → Actions.

### Q: What if I don't want AI code review on every PR?
**A:** Edit `.github/workflows/ai-code-review.yml` and add a label filter:
```yaml
on:
  pull_request:
    types: [opened, synchronize, reopened, labeled]

jobs:
  ai_review:
    if: contains(github.event.pull_request.labels.*.name, 'ai-review')
```

### Q: How much does this cost?
**A:** GitHub Actions includes generous free minutes:
- Public repos: Unlimited
- Private repos: 2,000 minutes/month free (then paid)

Our workflows typically use ~10-15 minutes per full run.

## Next Steps

Once you're comfortable with the basics:

1. ✅ **Read the full documentation:** `docs/guides/automation.md`
2. ✅ **Customize for your needs:** Adjust thresholds, schedules
3. ✅ **Review first week of reports:** Track what works
4. ✅ **Share with team:** Ensure everyone understands the system
5. ✅ **Iterate:** Adjust based on feedback

## Getting Help

**Issues with setup?**
1. Check GitHub Actions logs
2. Run scripts locally to test
3. Review workflow syntax
4. Open an issue in the repository

**Questions about reports?**
- See "Interpreting Reports" in main automation guide
- Review examples in workflow documentation
- Check artifact downloads for full details

## Success Metrics

After 1 month, you should see:

- 📊 **Metrics:** Baseline established for all quality metrics
- 🐛 **Issues:** Automated issues helping track improvements
- 🔒 **Security:** Regular dependency updates merged
- 📚 **Documentation:** Coverage improving
- ✅ **Tests:** Coverage stable or increasing
- 👥 **Team:** Everyone understands the system

## Quick Reference Card

```
┌─────────────────────────────────────────────────┐
│           AUTOMATION QUICK REFERENCE             │
├─────────────────────────────────────────────────┤
│                                                   │
│  📊 Status: GitHub → Actions tab                │
│  🔧 Trigger: gh workflow run <workflow>         │
│  📥 Download: gh run download <run-id>          │
│  📖 Reports: Check issues with 'automated' label│
│  🚀 Local: ./scripts/analyze_code_quality.sh   │
│                                                   │
│  🔴 Red (Fail): Must fix before merge           │
│  🟡 Yellow (Warn): Address soon                 │
│  🟢 Green (Pass): All good!                     │
│                                                   │
└─────────────────────────────────────────────────┘
```

---

**Ready to dive deeper?** Read the [Complete Automation Guide](automation.md)

**Need help?** Open an issue with the `automation` label.

**Happy automating! 🚀**
