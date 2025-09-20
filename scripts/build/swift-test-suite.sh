#!/bin/bash

# ===============================================================================
# ForceQUIT - Comprehensive Test Suite
# SWARM 2.0 Framework - BUILD_SYSTEM_DEVELOPER
# ===============================================================================
# Automated testing workflows: Unit tests, Integration tests, Performance tests
# Supports: Parallel execution, Coverage reporting, CI/CD integration

set -e

# Configuration
PROJECT_NAME="ForceQUIT"
TEST_DIR="Tests"
COVERAGE_DIR="coverage"
REPORTS_DIR="test-reports"

# Test configuration
RUN_UNIT_TESTS=true
RUN_INTEGRATION_TESTS=true  
RUN_PERFORMANCE_TESTS=true
RUN_SECURITY_TESTS=true
RUN_UI_TESTS=false  # Requires UI testing setup
GENERATE_COVERAGE=true
PARALLEL_TESTS=true
VERBOSE_OUTPUT=false
FAIL_FAST=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --unit-only)
            RUN_UNIT_TESTS=true
            RUN_INTEGRATION_TESTS=false
            RUN_PERFORMANCE_TESTS=false
            RUN_SECURITY_TESTS=false
            shift
            ;;
        --integration-only)
            RUN_UNIT_TESTS=false
            RUN_INTEGRATION_TESTS=true
            RUN_PERFORMANCE_TESTS=false
            RUN_SECURITY_TESTS=false
            shift
            ;;
        --performance-only)
            RUN_UNIT_TESTS=false
            RUN_INTEGRATION_TESTS=false
            RUN_PERFORMANCE_TESTS=true
            RUN_SECURITY_TESTS=false
            shift
            ;;
        --security-only)
            RUN_UNIT_TESTS=false
            RUN_INTEGRATION_TESTS=false
            RUN_PERFORMANCE_TESTS=false
            RUN_SECURITY_TESTS=true
            shift
            ;;
        --no-coverage)
            GENERATE_COVERAGE=false
            shift
            ;;
        --sequential)
            PARALLEL_TESTS=false
            shift
            ;;
        --verbose)
            VERBOSE_OUTPUT=true
            shift
            ;;
        --fail-fast)
            FAIL_FAST=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--unit-only|--integration-only|--performance-only|--security-only] [--no-coverage] [--sequential] [--verbose] [--fail-fast]"
            exit 1
            ;;
    esac
done

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${BLUE}[TEST SUITE]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    if [[ "$FAIL_FAST" == true ]]; then
        exit 1
    fi
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

# Test result tracking
TESTS_PASSED=0
TESTS_FAILED=0
TEST_RESULTS=()

record_test_result() {
    local test_name="$1"
    local result="$2"
    local duration="$3"
    
    TEST_RESULTS+=("$test_name:$result:$duration")
    
    if [[ "$result" == "PASS" ]]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Header
echo -e "${CYAN}===============================================================================${NC}"
echo -e "${WHITE}                ForceQUIT Comprehensive Test Suite${NC}"
echo -e "${WHITE}                BUILD_SYSTEM_DEVELOPER - SWARM 2.0${NC}"
echo -e "${CYAN}===============================================================================${NC}"

info "Test configuration:"
info "   • Unit Tests: $RUN_UNIT_TESTS"
info "   • Integration Tests: $RUN_INTEGRATION_TESTS"
info "   • Performance Tests: $RUN_PERFORMANCE_TESTS"
info "   • Security Tests: $RUN_SECURITY_TESTS"
info "   • Coverage Generation: $GENERATE_COVERAGE"
info "   • Parallel Execution: $PARALLEL_TESTS"

# Create directories
mkdir -p "$REPORTS_DIR" "$COVERAGE_DIR"

# Validate environment
log "🔍 Validating test environment..."
if ! command -v swift &> /dev/null; then
    error "Swift toolchain not found"
fi

if [ ! -f "Package.swift" ]; then
    error "Package.swift not found. Run from project root."
fi

# Check if test directories exist
if [ ! -d "$TEST_DIR" ]; then
    warn "Tests directory not found. Creating test structure..."
    mkdir -p "$TEST_DIR/ForceQUITTests"
    mkdir -p "$TEST_DIR/ForceQUITSecurityTests" 
    mkdir -p "$TEST_DIR/ForceQUITAnalyticsTests"
    mkdir -p "$TEST_DIR/ForceQUITPerformanceTests"
fi

success "Test environment validated"

# Run unit tests
run_unit_tests() {
    if [[ "$RUN_UNIT_TESTS" != true ]]; then
        return 0
    fi
    
    log "🧪 Running unit tests..."
    local start_time=$(date +%s)
    
    local test_flags=()
    if [[ "$VERBOSE_OUTPUT" == true ]]; then
        test_flags+=("--verbose")
    fi
    
    if [[ "$PARALLEL_TESTS" == true ]]; then
        test_flags+=("--parallel")
    fi
    
    if swift test "${test_flags[@]}" --filter "ForceQUITTests"; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        success "Unit tests passed in ${duration}s"
        record_test_result "Unit Tests" "PASS" "$duration"
        return 0
    else
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        error "Unit tests failed after ${duration}s"
        record_test_result "Unit Tests" "FAIL" "$duration"
        return 1
    fi
}

# Run integration tests
run_integration_tests() {
    if [[ "$RUN_INTEGRATION_TESTS" != true ]]; then
        return 0
    fi
    
    log "🔗 Running integration tests..."
    local start_time=$(date +%s)
    
    # Integration tests may require special setup
    if swift test --filter "Integration"; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        success "Integration tests passed in ${duration}s"
        record_test_result "Integration Tests" "PASS" "$duration"
        return 0
    else
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        error "Integration tests failed after ${duration}s"
        record_test_result "Integration Tests" "FAIL" "$duration"
        return 1
    fi
}

# Run performance tests
run_performance_tests() {
    if [[ "$RUN_PERFORMANCE_TESTS" != true ]]; then
        return 0
    fi
    
    log "⚡ Running performance tests..."
    local start_time=$(date +%s)
    
    if swift test --filter "ForceQUITPerformanceTests"; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        success "Performance tests passed in ${duration}s"
        record_test_result "Performance Tests" "PASS" "$duration"
        return 0
    else
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        error "Performance tests failed after ${duration}s"
        record_test_result "Performance Tests" "FAIL" "$duration"
        return 1
    fi
}

# Run security tests
run_security_tests() {
    if [[ "$RUN_SECURITY_TESTS" != true ]]; then
        return 0
    fi
    
    log "🔒 Running security tests..."
    local start_time=$(date +%s)
    
    if swift test --filter "ForceQUITSecurityTests"; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        success "Security tests passed in ${duration}s"
        record_test_result "Security Tests" "PASS" "$duration"
        return 0
    else
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        error "Security tests failed after ${duration}s"
        record_test_result "Security Tests" "FAIL" "$duration"
        return 1
    fi
}

# Generate code coverage
generate_coverage() {
    if [[ "$GENERATE_COVERAGE" != true ]]; then
        return 0
    fi
    
    log "📊 Generating code coverage report..."
    
    # Run tests with coverage
    swift test --enable-code-coverage
    
    # Generate coverage report (if llvm-cov is available)
    if command -v llvm-cov &> /dev/null; then
        # Find the test executable
        local test_binary=$(find .build -name "*PackageTests" -type f | head -1)
        
        if [ -n "$test_binary" ]; then
            llvm-cov show "$test_binary" \
                -instr-profile=.build/debug/codecov/default.profdata \
                --format=html \
                --output-dir="$COVERAGE_DIR" \
                --show-line-counts-or-regions \
                --show-instantiations
            
            success "Coverage report generated: $COVERAGE_DIR/index.html"
        else
            warn "Test binary not found - coverage report not generated"
        fi
    else
        warn "llvm-cov not found - HTML coverage report not generated"
    fi
}

# Create test results report
create_test_report() {
    log "📋 Creating test report..."
    
    local report_file="$REPORTS_DIR/test-results.html"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    
    cat > "$report_file" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>ForceQUIT Test Results</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .header { background: #f0f0f0; padding: 20px; border-radius: 5px; }
        .passed { color: #28a745; }
        .failed { color: #dc3545; }
        .summary { margin: 20px 0; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { border: 1px solid #ddd; padding: 12px; text-align: left; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <div class="header">
        <h1>ForceQUIT Test Results</h1>
        <p><strong>Generated:</strong> $timestamp</p>
        <p><strong>Project:</strong> $PROJECT_NAME</p>
    </div>
    
    <div class="summary">
        <h2>Summary</h2>
        <p class="passed"><strong>Tests Passed:</strong> $TESTS_PASSED</p>
        <p class="failed"><strong>Tests Failed:</strong> $TESTS_FAILED</p>
        <p><strong>Total Tests:</strong> $((TESTS_PASSED + TESTS_FAILED))</p>
    </div>
    
    <h2>Test Results</h2>
    <table>
        <tr>
            <th>Test Suite</th>
            <th>Result</th>
            <th>Duration (s)</th>
        </tr>
EOF

    for result in "${TEST_RESULTS[@]}"; do
        IFS=':' read -ra PARTS <<< "$result"
        local test_name="${PARTS[0]}"
        local test_result="${PARTS[1]}"
        local test_duration="${PARTS[2]}"
        
        local css_class
        if [[ "$test_result" == "PASS" ]]; then
            css_class="passed"
        else
            css_class="failed"
        fi
        
        cat >> "$report_file" << EOF
        <tr>
            <td>$test_name</td>
            <td class="$css_class">$test_result</td>
            <td>$test_duration</td>
        </tr>
EOF
    done
    
    cat >> "$report_file" << EOF
    </table>
</body>
</html>
EOF

    success "Test report created: $report_file"
}

# Main test execution
main() {
    local overall_start_time=$(date +%s)
    
    # Run all test suites
    run_unit_tests
    run_integration_tests
    run_performance_tests
    run_security_tests
    
    # Generate coverage and reports
    generate_coverage
    create_test_report
    
    local overall_end_time=$(date +%s)
    local total_time=$((overall_end_time - overall_start_time))
    
    # Final summary
    echo -e "${GREEN}===============================================================================${NC}"
    echo -e "${WHITE}                Test Suite Complete!${NC}"
    echo -e "${GREEN}===============================================================================${NC}"
    
    success "📊 Final Results:"
    info "   • Tests Passed: $TESTS_PASSED"
    info "   • Tests Failed: $TESTS_FAILED"
    info "   • Total Time: ${total_time}s"
    info "   • Coverage Report: $COVERAGE_DIR/index.html"
    info "   • Test Report: $REPORTS_DIR/test-results.html"
    
    if [[ $TESTS_FAILED -gt 0 ]]; then
        error "❌ Some tests failed!"
        exit 1
    else
        success "✅ All tests passed!"
        exit 0
    fi
}

# Trap to cleanup on exit
cleanup() {
    info "🧹 Cleaning up temporary files..."
    # Add any cleanup tasks here
}
trap cleanup EXIT

main "$@"