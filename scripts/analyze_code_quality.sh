#!/usr/bin/env bash

# AI Self-Improvement: Code Quality Analysis Script
# This script performs comprehensive code quality analysis

set -e

echo "🔍 Starting Code Quality Analysis..."
echo ""

# Create output directory
mkdir -p reports

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print section headers
print_header() {
    echo ""
    echo "============================================"
    echo "$1"
    echo "============================================"
    echo ""
}

# 1. Code Statistics
print_header "📊 Code Statistics"
echo "Counting lines of code..."

total_lib=$(find lib -name "*.ex" 2>/dev/null | xargs wc -l 2>/dev/null | tail -1 | awk '{print $1}' || echo "0")
total_test=$(find test -name "*.exs" 2>/dev/null | xargs wc -l 2>/dev/null | tail -1 | awk '{print $1}' || echo "0")
module_count=$(find lib -name "*.ex" 2>/dev/null | wc -l)
test_file_count=$(find test -name "*.exs" 2>/dev/null | wc -l)

echo "Production code: $total_lib lines"
echo "Test code: $total_test lines"
echo "Modules: $module_count"
echo "Test files: $test_file_count"

if [ "$total_lib" -gt 0 ]; then
    test_ratio=$(echo "scale=2; $total_test / $total_lib" | bc)
    echo "Test-to-code ratio: $test_ratio"
fi

# 2. Run Credo Analysis
print_header "🎯 Running Credo Static Analysis"
if mix credo --strict 2>/dev/null; then
    echo -e "${GREEN}✓ Credo passed with no issues${NC}"
else
    echo -e "${YELLOW}⚠ Credo found issues (see above)${NC}"
fi

# 3. Check Code Formatting
print_header "💅 Checking Code Formatting"
if mix format --check-formatted 2>/dev/null; then
    echo -e "${GREEN}✓ Code is properly formatted${NC}"
else
    echo -e "${YELLOW}⚠ Code formatting issues found${NC}"
    echo "Run 'mix format' to fix"
fi

# 4. Check for Unused Dependencies
print_header "📦 Checking for Unused Dependencies"
if mix deps.unlock --check-unused 2>/dev/null; then
    echo -e "${GREEN}✓ No unused dependencies${NC}"
else
    echo -e "${YELLOW}⚠ Unused dependencies found${NC}"
fi

# 5. Documentation Coverage
print_header "📚 Analyzing Documentation Coverage"

total_modules=0
documented_modules=0

for file in $(find lib -name "*.ex"); do
    total_modules=$((total_modules + 1))
    if grep -q "@moduledoc" "$file"; then
        documented_modules=$((documented_modules + 1))
    fi
done

if [ "$total_modules" -gt 0 ]; then
    doc_coverage=$((documented_modules * 100 / total_modules))
    echo "Module documentation coverage: $doc_coverage% ($documented_modules/$total_modules)"

    if [ "$doc_coverage" -ge 80 ]; then
        echo -e "${GREEN}✓ Good documentation coverage${NC}"
    else
        echo -e "${YELLOW}⚠ Documentation coverage below 80%${NC}"
    fi
fi

# 6. Type Specification Coverage
print_header "🔤 Analyzing Type Specification Coverage"

total_public_funcs=0
total_specs=0

for file in $(find lib -name "*.ex"); do
    public_funcs=$(grep -c "^\s*def " "$file" 2>/dev/null || echo 0)
    specs=$(grep -c "@spec" "$file" 2>/dev/null || echo 0)
    total_public_funcs=$((total_public_funcs + public_funcs))
    total_specs=$((total_specs + specs))
done

if [ "$total_public_funcs" -gt 0 ]; then
    spec_coverage=$((total_specs * 100 / total_public_funcs))
    echo "Type specification coverage: $spec_coverage% ($total_specs/$total_public_funcs)"

    if [ "$spec_coverage" -ge 70 ]; then
        echo -e "${GREEN}✓ Good type specification coverage${NC}"
    else
        echo -e "${YELLOW}⚠ Type specification coverage below 70%${NC}"
    fi
fi

# 7. Test Coverage
print_header "🧪 Analyzing Test Coverage"
if mix test --cover 2>/dev/null; then
    echo -e "${GREEN}✓ Tests passed${NC}"
else
    echo -e "${RED}✗ Tests failed${NC}"
fi

# 8. Look for Code Smells
print_header "👃 Detecting Code Smells"

# TODO/FIXME comments
todo_count=$(grep -r "TODO\|FIXME" lib test 2>/dev/null | wc -l || echo 0)
echo "TODO/FIXME comments found: $todo_count"

if [ "$todo_count" -eq 0 ]; then
    echo -e "${GREEN}✓ No TODO/FIXME comments${NC}"
else
    echo -e "${YELLOW}⚠ Consider addressing TODO/FIXME comments${NC}"
fi

# Long functions (>50 lines)
echo ""
echo "Checking for long functions..."
long_func_count=0
for file in $(find lib -name "*.ex"); do
    long_funcs=$(awk '/^\s*def / {start=NR} /^\s*end\s*$/ {if (NR-start > 50) print FILENAME ":" start}' "$file" 2>/dev/null | wc -l)
    long_func_count=$((long_func_count + long_funcs))
done

if [ "$long_func_count" -eq 0 ]; then
    echo -e "${GREEN}✓ No overly long functions detected${NC}"
else
    echo -e "${YELLOW}⚠ Found $long_func_count functions longer than 50 lines${NC}"
fi

# 9. Generate Summary Report
print_header "📋 Quality Summary"

cat > reports/quality_summary.txt << EOF
Code Quality Analysis Report
Generated: $(date)

STATISTICS
----------
Production code: $total_lib lines
Test code: $total_test lines
Modules: $module_count
Test files: $test_file_count

COVERAGE
--------
Module documentation: $doc_coverage%
Type specifications: $spec_coverage%

CODE HEALTH
-----------
TODO/FIXME comments: $todo_count
Long functions (>50 lines): $long_func_count

RECOMMENDATIONS
--------------
EOF

# Add recommendations based on findings
if [ "$doc_coverage" -lt 80 ]; then
    echo "- Improve module documentation coverage to >80%" >> reports/quality_summary.txt
fi

if [ "$spec_coverage" -lt 70 ]; then
    echo "- Add type specifications to public functions (target >70%)" >> reports/quality_summary.txt
fi

if [ "$todo_count" -gt 10 ]; then
    echo "- Address or create issues for TODO/FIXME comments" >> reports/quality_summary.txt
fi

if [ "$long_func_count" -gt 0 ]; then
    echo "- Refactor long functions into smaller, focused functions" >> reports/quality_summary.txt
fi

echo "" >> reports/quality_summary.txt
echo "For detailed analysis, run individual tools:" >> reports/quality_summary.txt
echo "  - mix credo --strict" >> reports/quality_summary.txt
echo "  - mix dialyzer" >> reports/quality_summary.txt
echo "  - mix coveralls.html" >> reports/quality_summary.txt

cat reports/quality_summary.txt

echo ""
echo -e "${GREEN}✓ Analysis complete! Report saved to reports/quality_summary.txt${NC}"
