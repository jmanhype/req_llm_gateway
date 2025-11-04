#!/usr/bin/env bash

# AI Self-Improvement: Generate Improvement Suggestions
# This script analyzes the codebase and generates actionable improvement suggestions

set -e

echo "🤖 Generating AI-Powered Improvement Suggestions..."
echo ""

# Create output directory
mkdir -p reports/suggestions

# Function to print section headers
print_header() {
    echo ""
    echo "============================================"
    echo "$1"
    echo "============================================"
    echo ""
}

# Initialize suggestion counter
suggestion_count=0

# Create main suggestions file
SUGGESTIONS_FILE="reports/suggestions/improvements_$(date +%Y%m%d).md"

cat > "$SUGGESTIONS_FILE" << 'EOF'
# Code Improvement Suggestions

This report contains AI-generated suggestions for improving the codebase.

---

EOF

# 1. Find modules without tests
print_header "🧪 Test Coverage Suggestions"

cat >> "$SUGGESTIONS_FILE" << 'EOF'
## Testing Improvements

### Modules Without Test Files

EOF

for file in $(find lib -name "*.ex"); do
    module_path=$(echo "$file" | sed 's|lib/||')
    test_path="test/${module_path%.*}_test.exs"

    if [ ! -f "$test_path" ]; then
        echo "- [ ] Create test file for: \`$file\`" >> "$SUGGESTIONS_FILE"
        echo "  - Suggested path: \`$test_path\`" >> "$SUGGESTIONS_FILE"
        suggestion_count=$((suggestion_count + 1))
    fi
done

# 2. Find modules without documentation
print_header "📚 Documentation Suggestions"

cat >> "$SUGGESTIONS_FILE" << 'EOF'

## Documentation Improvements

### Modules Without @moduledoc

EOF

for file in $(find lib -name "*.ex"); do
    if ! grep -q "@moduledoc" "$file"; then
        echo "- [ ] Add module documentation to: \`$file\`" >> "$SUGGESTIONS_FILE"
        suggestion_count=$((suggestion_count + 1))
    fi
done

cat >> "$SUGGESTIONS_FILE" << 'EOF'

### Functions Without @doc

EOF

for file in $(find lib -name "*.ex"); do
    # Simple heuristic: find 'def ' not preceded by @doc
    undoc_funcs=$(grep -B1 "^\s*def " "$file" | grep -v "@doc" | grep "def " | wc -l)

    if [ "$undoc_funcs" -gt 0 ]; then
        echo "- [ ] Add function documentation to: \`$file\` ($undoc_funcs functions)" >> "$SUGGESTIONS_FILE"
        suggestion_count=$((suggestion_count + 1))
    fi
done

# 3. Find functions without type specs
print_header "🔤 Type Specification Suggestions"

cat >> "$SUGGESTIONS_FILE" << 'EOF'

## Type Specification Improvements

### Functions Without @spec

EOF

for file in $(find lib -name "*.ex"); do
    public_funcs=$(grep -c "^\s*def " "$file" 2>/dev/null || echo 0)
    specs=$(grep -c "@spec" "$file" 2>/dev/null || echo 0)

    if [ "$public_funcs" -gt "$specs" ]; then
        missing=$((public_funcs - specs))
        echo "- [ ] Add type specs to: \`$file\` ($missing functions)" >> "$SUGGESTIONS_FILE"
        suggestion_count=$((suggestion_count + 1))
    fi
done

# 4. Performance optimization suggestions
print_header "⚡ Performance Suggestions"

cat >> "$SUGGESTIONS_FILE" << 'EOF'

## Performance Optimization Opportunities

### Enum Usage Patterns

EOF

# Look for potential optimization opportunities
enum_map_count=$(grep -r "Enum.map" lib 2>/dev/null | wc -l || echo 0)

if [ "$enum_map_count" -gt 10 ]; then
    echo "- [ ] Review \`Enum.map\` usage ($enum_map_count occurrences)" >> "$SUGGESTIONS_FILE"
    echo "  - Consider using comprehensions for better performance" >> "$SUGGESTIONS_FILE"
    echo "  - Consider using \`Stream\` for large collections" >> "$SUGGESTIONS_FILE"
    suggestion_count=$((suggestion_count + 1))
fi

cat >> "$SUGGESTIONS_FILE" << 'EOF'

### Potential Caching Opportunities

- [ ] Review frequently accessed data
- [ ] Consider ETS caching for read-heavy operations
- [ ] Evaluate memoization for expensive calculations

### Concurrency Improvements

- [ ] Review opportunities for parallel processing with Task.async
- [ ] Consider GenServer for stateful operations
- [ ] Evaluate pooling for external resource connections

EOF

# 5. Code quality improvements
print_header "✨ Code Quality Suggestions"

cat >> "$SUGGESTIONS_FILE" << 'EOF'

## Code Quality Enhancements

### TODO/FIXME Comments

EOF

# Find and list TODO/FIXME comments
if grep -rn "TODO\|FIXME" lib test 2>/dev/null | head -20 > /tmp/todos.txt; then
    if [ -s /tmp/todos.txt ]; then
        while IFS= read -r line; do
            echo "- [ ] Address: \`$line\`" >> "$SUGGESTIONS_FILE"
            suggestion_count=$((suggestion_count + 1))
        done < /tmp/todos.txt
    else
        echo "✅ No TODO/FIXME comments found" >> "$SUGGESTIONS_FILE"
    fi
fi

cat >> "$SUGGESTIONS_FILE" << 'EOF'

### Long Functions

EOF

# Find long functions
long_func_found=false
for file in $(find lib -name "*.ex"); do
    long_funcs=$(awk '/^\s*def / {start=NR; name=$2} /^\s*end\s*$/ {if (NR-start > 30) print FILENAME ":" start " - " name " (" NR-start " lines)"}' "$file" 2>/dev/null)

    if [ -n "$long_funcs" ]; then
        echo "- [ ] Refactor long function in \`$file\`" >> "$SUGGESTIONS_FILE"
        echo "$long_funcs" | while read -r func; do
            echo "  - $func" >> "$SUGGESTIONS_FILE"
        done
        suggestion_count=$((suggestion_count + 1))
        long_func_found=true
    fi
done

if [ "$long_func_found" = false ]; then
    echo "✅ No overly long functions detected" >> "$SUGGESTIONS_FILE"
fi

# 6. Security suggestions
print_header "🔒 Security Suggestions"

cat >> "$SUGGESTIONS_FILE" << 'EOF'

## Security Enhancements

### Best Practices Checklist

- [ ] Review all user input validation
- [ ] Ensure secrets are not hardcoded
- [ ] Verify authentication on all protected endpoints
- [ ] Check authorization for resource access
- [ ] Implement rate limiting for public APIs
- [ ] Review error messages for information leakage
- [ ] Ensure HTTPS in production
- [ ] Configure security headers
- [ ] Implement CORS policy
- [ ] Regular dependency security audits

### Specific Checks

EOF

# Check for potential hardcoded secrets
if grep -r "password\s*=\s*['\"]" lib/ test/ 2>/dev/null | grep -v test | grep -v "#" > /dev/null; then
    echo "⚠️ - [ ] Review potential hardcoded passwords" >> "$SUGGESTIONS_FILE"
    suggestion_count=$((suggestion_count + 1))
else
    echo "✅ No hardcoded passwords detected" >> "$SUGGESTIONS_FILE"
fi

# 7. Architecture suggestions
print_header "🏗️ Architecture Suggestions"

cat >> "$SUGGESTIONS_FILE" << 'EOF'

## Architecture Improvements

### Module Organization

EOF

# Check for large modules
large_modules_found=false
for file in $(find lib -name "*.ex"); do
    lines=$(wc -l < "$file")
    if [ "$lines" -gt 300 ]; then
        echo "- [ ] Consider splitting large module: \`$file\` ($lines lines)" >> "$SUGGESTIONS_FILE"
        suggestion_count=$((suggestion_count + 1))
        large_modules_found=true
    fi
done

if [ "$large_modules_found" = false ]; then
    echo "✅ No overly large modules detected" >> "$SUGGESTIONS_FILE"
fi

cat >> "$SUGGESTIONS_FILE" << 'EOF'

### Suggested Patterns

- [ ] Consider using protocols for polymorphic behavior
- [ ] Evaluate opportunities for supervision trees
- [ ] Review GenServer usage for stateful processes
- [ ] Consider using behaviours for common patterns

EOF

# 8. Add summary and prioritization
cat >> "$SUGGESTIONS_FILE" << EOF

---

## Summary

**Total Suggestions Generated:** $suggestion_count

### Priority Recommendations

1. **High Priority**
   - Security vulnerabilities
   - Missing tests for critical modules
   - Outdated dependencies with CVEs

2. **Medium Priority**
   - Documentation improvements
   - Type specification additions
   - Code quality issues

3. **Low Priority**
   - Code style improvements
   - Performance optimizations
   - Refactoring opportunities

### Next Steps

1. Review suggestions with the team
2. Create issues for high-priority items
3. Schedule improvements in upcoming sprints
4. Track progress in the quality dashboard

---

*Generated: $(date)*
*Tool: AI Self-Improvement System*
EOF

echo ""
echo "✅ Generated $suggestion_count improvement suggestions"
echo "📄 Report saved to: $SUGGESTIONS_FILE"
echo ""

# Output summary to console
cat "$SUGGESTIONS_FILE"
