#!/bin/bash

# ForceQUIT Test Script
# Comprehensive testing suite for macOS Swift applications

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="ForceQUIT"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_DIR="$PROJECT_ROOT/tests"
COVERAGE_DIR="$PROJECT_ROOT/coverage"

# Test options
RUN_UNIT_TESTS=true
RUN_INTEGRATION_TESTS=false
RUN_UI_TESTS=false
GENERATE_COVERAGE=false
VERBOSE=false
CLEAN=false

# Logging
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Help function
show_help() {
    cat << EOF
ForceQUIT Test Suite

Usage: $0 [OPTIONS]

OPTIONS:
    --unit                 Run unit tests [default: true]
    --integration          Run integration tests
    --ui                   Run UI tests
    --coverage             Generate code coverage report
    --verbose              Verbose output
    --clean                Clean test artifacts before testing
    --help                 Show this help message

EXAMPLES:
    $0                                    # Run unit tests only
    $0 --integration --coverage           # Run integration tests with coverage
    $0 --unit --integration --ui          # Run all test suites
    $0 --clean --coverage                 # Clean and run with coverage

EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --unit)
                RUN_UNIT_TESTS=true
                shift
                ;;
            --integration)
                RUN_INTEGRATION_TESTS=true
                shift
                ;;
            --ui)
                RUN_UI_TESTS=true
                shift
                ;;
            --coverage)
                GENERATE_COVERAGE=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --clean)
                CLEAN=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Check dependencies
check_dependencies() {
    log "Checking test dependencies..."

    # Check for Swift
    if ! command -v swift &> /dev/null; then
        log_error "Swift is not installed. Please install Xcode or Swift toolchain."
        exit 1
    fi

    # Check for xctest (should be included with Swift)
    if ! swift test --version &> /dev/null; then
        log_error "Swift testing infrastructure is not available."
        exit 1
    fi

    log_success "Test dependencies check passed"
}

# Clean test artifacts
clean_tests() {
    if [[ "$CLEAN" == true ]]; then
        log "Cleaning test artifacts..."
        rm -rf "$COVERAGE_DIR"
        swift package clean
        log_success "Test artifacts cleaned"
    fi
}

# Create directories
create_directories() {
    mkdir -p "$COVERAGE_DIR"
}

# Run unit tests
run_unit_tests() {
    if [[ "$RUN_UNIT_TESTS" == true ]]; then
        log "Running unit tests..."

        cd "$PROJECT_ROOT"

        local test_args=()

        if [[ "$GENERATE_COVERAGE" == true ]]; then
            test_args+=("--enable-code-coverage")
        fi

        if [[ "$VERBOSE" == true ]]; then
            test_args+=("--verbose")
        fi

        # Run unit tests
        if swift test "${test_args[@]}" --filter "UnitTests"; then
            log_success "Unit tests passed"
        else
            log_error "Unit tests failed"
            return 1
        fi
    fi
}

# Run integration tests
run_integration_tests() {
    if [[ "$RUN_INTEGRATION_TESTS" == true ]]; then
        log "Running integration tests..."

        cd "$PROJECT_ROOT"

        local test_args=()

        if [[ "$GENERATE_COVERAGE" == true ]]; then
            test_args+=("--enable-code-coverage")
        fi

        if [[ "$VERBOSE" == true ]]; then
            test_args+=("--verbose")
        fi

        # Run integration tests
        if swift test "${test_args[@]}" --filter "IntegrationTests"; then
            log_success "Integration tests passed"
        else
            log_error "Integration tests failed"
            return 1
        fi
    fi
}

# Run UI tests
run_ui_tests() {
    if [[ "$RUN_UI_TESTS" == true ]]; then
        log "Running UI tests..."

        cd "$PROJECT_ROOT"

        local test_args=()

        if [[ "$GENERATE_COVERAGE" == true ]]; then
            test_args+=("--enable-code-coverage")
        fi

        if [[ "$VERBOSE" == true ]]; then
            test_args+=("--verbose")
        fi

        # Run UI tests (these may require special setup)
        if swift test "${test_args[@]}" --filter "UITests"; then
            log_success "UI tests passed"
        else
            log_error "UI tests failed"
            return 1
        fi
    fi
}

# Generate coverage report
generate_coverage() {
    if [[ "$GENERATE_COVERAGE" == true ]]; then
        log "Generating code coverage report..."

        cd "$PROJECT_ROOT"

        # Generate coverage data
        swift test --enable-code-coverage

        # Find coverage file
        local coverage_file=$(find .build -name "*.profdata" | head -1)

        if [[ -z "$coverage_file" ]]; then
            log_warning "No coverage data found"
            return 1
        fi

        # Generate coverage report
        xcrun llvm-cov report \
            -instr-profile="$coverage_file" \
            -object=".build/release/ForceQUIT" \
            > "$COVERAGE_DIR/coverage.txt"

        # Generate HTML coverage report (if available)
        if command -v genhtml &> /dev/null; then
            xcrun llvm-cov export \
                -instr-profile="$coverage_file" \
                -object=".build/release/ForceQUIT" \
                -format="lcov" \
                > "$COVERAGE_DIR/coverage.lcov"

            genhtml "$COVERAGE_DIR/coverage.lcov" \
                --output-directory "$COVERAGE_DIR/html" \
                --title "$PROJECT_NAME Coverage Report"
        fi

        log_success "Coverage report generated in $COVERAGE_DIR"

        # Display coverage summary
        if [[ -f "$COVERAGE_DIR/coverage.txt" ]]; then
            echo
            log "Coverage Summary:"
            cat "$COVERAGE_DIR/coverage.txt" | tail -5
        fi
    fi
}

# Run basic build test
run_build_test() {
    log "Running build test..."

    cd "$PROJECT_ROOT"

    # Test debug build
    if swift build -c debug; then
        log_success "Debug build test passed"
    else
        log_error "Debug build test failed"
        return 1
    fi

    # Test release build
    if swift build -c release; then
        log_success "Release build test passed"
    else
        log_error "Release build test failed"
        return 1
    fi
}

# Run linting (if SwiftLint is available)
run_linting() {
    if command -v swiftlint &> /dev/null; then
        log "Running SwiftLint..."

        cd "$PROJECT_ROOT"

        if swiftlint lint; then
            log_success "SwiftLint passed"
        else
            log_warning "SwiftLint found issues"
        fi
    else
        log_warning "SwiftLint not available, skipping linting"
    fi
}

# Run security analysis
run_security_analysis() {
    log "Running basic security analysis..."

    # Check for common security issues in Swift code
    local security_issues=0

    # Check for hardcoded secrets (basic patterns)
    if grep -r -i -E "(password|secret|key|token)\s*=\s*\"[^\"]+\"" Sources/ --include="*.swift" &> /dev/null; then
        log_warning "Potential hardcoded secrets found"
        ((security_issues++))
    fi

    # Check for insecure functions
    if grep -r "UnsafeMutablePointer" Sources/ --include="*.swift" &> /dev/null; then
        log_warning "Unsafe memory operations found"
        ((security_issues++))
    fi

    if [[ $security_issues -eq 0 ]]; then
        log_success "No obvious security issues found"
    else
        log_warning "Found $security_issues potential security issues"
    fi
}

# Performance analysis
run_performance_analysis() {
    log "Running basic performance analysis..."

    cd "$PROJECT_ROOT"

    # Check build time
    local start_time=$(date +%s)
    swift build -c release
    local end_time=$(date +%s)
    local build_time=$((end_time - start_time))

    log "Build time: ${build_time}s"

    # Check binary size
    if [[ -f ".build/release/ForceQUIT" ]]; then
        local binary_size=$(du -h ".build/release/ForceQUIT" | cut -f1)
        log "Binary size: $binary_size"
    fi

    log_success "Performance analysis completed"
}

# Display test summary
display_summary() {
    log "Test Summary:"
    log "  Unit Tests: $RUN_UNIT_TESTS"
    log "  Integration Tests: $RUN_INTEGRATION_TESTS"
    log "  UI Tests: $RUN_UI_TESTS"
    log "  Coverage: $GENERATE_COVERAGE"
    log "  Build Test: Completed"
    log "  Linting: Completed"
    log "  Security Analysis: Completed"
    log "  Performance Analysis: Completed"

    if [[ "$GENERATE_COVERAGE" == true && -f "$COVERAGE_DIR/coverage.txt" ]]; then
        echo
        log "Coverage reports generated in $COVERAGE_DIR"
    fi

    log_success "Test suite completed!"
}

# Main test function
main() {
    parse_args "$@"

    log "Starting $PROJECT_NAME test suite..."

    check_dependencies
    clean_tests
    create_directories
    run_build_test
    run_unit_tests
    run_integration_tests
    run_ui_tests
    run_linting
    run_security_analysis
    run_performance_analysis
    generate_coverage
    display_summary
}

# Run main function with all arguments
main "$@"