# 🚀 PROVEN COMMANDS REFERENCE
## All Working Claude Code CLI Commands & Patterns

---

## 🔑 CRITICAL FLAGS (NEVER FORGET THESE)

### The Magic Combination
```bash
--model sonnet --verbose --dangerously-skip-permissions -p
```

### What Each Flag Does
- `--model sonnet` - Uses Claude Sonnet 4 (fast, excellent quality)
- `--model opus` - Uses Claude Opus 4.1 (slower, highest quality)
- `--dangerously-skip-permissions` - **ESSENTIAL** - Enables automation and file creation
- `--print` - Non-interactive mode for piping and background execution
- `&` - Background execution for parallel processing
- `wait` - Synchronization point for all parallel swarms

---

## 📝 Basic Swarm Patterns

**IMPORTANT**: Use the enhanced logging system for all SWARM executions. See `swarm-logging-monitoring-system.md` for complete integration.

### Enhanced Agent Execution (RECOMMENDED)
```bash
# Source the enhanced logging system
source enhanced-swarm-launcher.sh

# Initialize logging
init_swarm_logging

# Launch agents with comprehensive logging
launch_swarm_agent "AGENT_NAME" "TASK_DESCRIPTION"
```

### Legacy Single Agent Execution (Basic)
```bash
echo "TASK_DESCRIPTION" | claude --model sonnet --verbose --dangerously-skip-permissions -p > output.txt
```

### Parallel Swarm Execution (WORKING PATTERN)
```bash
echo "AGENT_1_TASK" | claude --model sonnet --verbose --dangerously-skip-permissions -p > agent1.txt &
echo "AGENT_2_TASK" | claude --model sonnet --verbose --dangerously-skip-permissions -p > agent2.txt &
echo "AGENT_3_TASK" | claude --model sonnet --verbose --dangerously-skip-permissions -p > agent3.txt &
wait
ls -la *.txt  # Verify files created
```

### Loop-Based Swarm Spawning
```bash
for i in {01..10}; do 
    echo "TASK_WITH_VARIABLE_$i" | claude --model sonnet --verbose --dangerously-skip-permissions -p > output_$i.txt &
done
wait
```

---

## 🧠 PRD Generation Swarm

### Complete PRD Generation (6 Parallel Agents)
```bash
# EXECUTIVE SUMMARY & BUSINESS CASE
echo "EXECUTIVE SUMMARY & BUSINESS CASE: Create an executive summary using CO-STAR framework for '[APP_IDEA]'. Include context, objective, success metrics, target audience, and response format. Reference relevant market analysis." | claude --model sonnet --verbose --dangerously-skip-permissions -p > prd_executive.txt &

# TECHNICAL ARCHITECTURE & MODULE BREAKDOWN  
echo "TECHNICAL ARCHITECTURE & MODULE BREAKDOWN: Define technical specifications and module architecture for '[APP_IDEA]'. Consider appropriate tech stack, data storage, APIs, and break into 5-7 implementable modules with dependencies." | claude --model sonnet --verbose --dangerously-skip-permissions -p > prd_architecture.txt &

# USER EXPERIENCE & INTERFACE DESIGN
echo "USER EXPERIENCE & INTERFACE DESIGN: Design comprehensive UX/UI requirements for '[APP_IDEA]'. Focus on platform-native patterns, accessibility (WCAG), theme systems, interaction patterns, keyboard shortcuts, and component hierarchy." | claude --model sonnet --verbose --dangerously-skip-permissions -p > prd_ux_ui.txt &

# FEATURE REQUIREMENTS & USER STORIES
echo "FEATURE REQUIREMENTS & USER STORIES: Analyze '[APP_IDEA]' and create detailed feature breakdown. Include must-have, should-have, could-have features. Write user stories, acceptance criteria, and edge cases." | claude --model sonnet --verbose --dangerously-skip-permissions -p > prd_features.txt &

# PERFORMANCE & QUALITY REQUIREMENTS
echo "PERFORMANCE & QUALITY REQUIREMENTS: Define performance benchmarks, validation criteria, and quality metrics for '[APP_IDEA]'. Include startup time, memory usage, responsiveness, and comprehensive testing strategy." | claude --model sonnet --verbose --dangerously-skip-permissions -p > prd_performance.txt &

# COMPETITIVE ANALYSIS & DIFFERENTIATION
echo "COMPETITIVE ANALYSIS & DIFFERENTIATION: Research existing apps similar to '[APP_IDEA]' and identify differentiation opportunities. What makes this unique? Market positioning and competitive advantages." | claude --model sonnet --verbose --dangerously-skip-permissions -p > prd_competitive.txt &

wait

# MASTER SYNTHESIS
cat prd_*.txt > combined_swarm_output.txt
echo "MASTER SYNTHESIS: Review all the swarm analysis in 'combined_swarm_output.txt' and create a comprehensive, professional PRD document following industry standards." | claude --model opus --verbose --dangerously-skip-permissions -p > FINAL_PRD.md
```

---

## 🔧 CodeFix Diagnostic Swarm

**ENHANCED VERSION**: Use `execute_codefix_swarm()` function from `swarm-logging-monitoring-system.md` for complete logging integration.

### Phase 1: Comprehensive Analysis (6 Parallel Agents)

#### Enhanced CodeFIX (RECOMMENDED)
```bash
# Source enhanced functions
source enhanced-swarm-launcher.sh
source codefix-swarm-with-logging.sh

# Execute with full logging
execute_codefix_swarm "/path/to/codebase"
```

#### Legacy CodeFIX (Basic)
```bash
# ARCHITECTURE ANALYSIS AGENT
echo "ARCHITECTURE ANALYSIS: Analyze this codebase structure and identify architectural issues, anti-patterns, technical debt, and structural problems. Focus on: file organization, dependency management, separation of concerns, scalability issues, maintainability problems.
CODEBASE_PATH: [path_to_codebase]" | claude --model sonnet --verbose --dangerously-skip-permissions -p > architecture_analysis.txt &

# SECURITY VULNERABILITY AGENT  
echo "SECURITY AUDIT: Perform comprehensive security analysis of this codebase. Identify: authentication flaws, authorization issues, input validation problems, XSS vulnerabilities, SQL injection risks, secret exposure, dependency vulnerabilities.
CODEBASE_PATH: [path_to_codebase]" | claude --model sonnet --verbose --dangerously-skip-permissions -p > security_audit.txt &

# PERFORMANCE ANALYSIS AGENT
echo "PERFORMANCE AUDIT: Analyze this codebase for performance bottlenecks, memory leaks, inefficient algorithms, database query issues, loading problems, resource usage optimization opportunities.
CODEBASE_PATH: [path_to_codebase]" | claude --model sonnet --verbose --dangerously-skip-permissions -p > performance_analysis.txt &

# CODE QUALITY AGENT
echo "CODE QUALITY AUDIT: Review code quality issues including: syntax errors, logic bugs, code smells, documentation gaps, test coverage, naming conventions, code duplication, unused code.
CODEBASE_PATH: [path_to_codebase]" | claude --model sonnet --verbose --dangerously-skip-permissions -p > quality_analysis.txt &

# DEPENDENCY HEALTH AGENT
echo "DEPENDENCY AUDIT: Analyze all dependencies for: outdated packages, security vulnerabilities, compatibility issues, unused dependencies, license conflicts, update recommendations.
CODEBASE_PATH: [path_to_codebase]" | claude --model sonnet --verbose --dangerously-skip-permissions -p > dependency_audit.txt &

# FUNCTIONALITY COMPLETENESS AGENT
echo "FUNCTIONALITY AUDIT: Identify incomplete features, missing implementations, broken functionality, API endpoints that don't work, UI components that are non-functional, integration issues.
CODEBASE_PATH: [path_to_codebase]" | claude --model sonnet --verbose --dangerously-skip-permissions -p > functionality_audit.txt &

wait
```

### Phase 2: Master Diagnosis Synthesis
```bash
# Combine all diagnostic outputs
cat *_analysis.txt *_audit.txt > combined_diagnostics.txt

# Generate comprehensive repair plan
echo "MASTER CODEFIX DIAGNOSIS: Analyze all diagnostic reports in 'combined_diagnostics.txt' and create a comprehensive codebase repair plan with prioritized issues and specific fixes." | claude --model sonnet --verbose --dangerously-skip-permissions -p > MASTER_REPAIR_PLAN.md
```

---

## 🔄 Code Review Swarm

### Real-Time Code Review (5 Parallel Agents)
```bash
review_code_block() {
    local code_block="$1"
    
    echo "SYNTAX & LOGIC REVIEW: Check this code for syntax errors and logic issues: $code_block" | claude --model sonnet --verbose --dangerously-skip-permissions -p > review_syntax.txt &
    
    echo "SECURITY REVIEW: Analyze this code for security vulnerabilities: $code_block" | claude --model sonnet --verbose --dangerously-skip-permissions -p > review_security.txt &
    
    echo "PERFORMANCE REVIEW: Check this code for performance issues: $code_block" | claude --model sonnet --verbose --dangerously-skip-permissions -p > review_performance.txt &
    
    echo "BEST PRACTICES REVIEW: Verify this code follows best practices: $code_block" | claude --model sonnet --verbose --dangerously-skip-permissions -p > review_practices.txt &
    
    echo "INTEGRATION REVIEW: Analyze integration with surrounding code: $code_block" | claude --model sonnet --verbose --dangerously-skip-permissions -p > review_integration.txt &
    
    wait
    
    # Synthesize all reviews
    cat review_*.txt > combined_reviews.txt
    echo "MASTER CODE REVIEW: Synthesize all reviews and provide final assessment" | claude --model sonnet --verbose --dangerously-skip-permissions -p > master_review.txt
}
```

---

## 🏗️ Build System Commands - COMPREHENSIVE ELECTRON BUILD SYSTEM

### Multi-Platform Build with Cleanup & Optimization
```bash
# MAXIMUM BUILD - All 42+ packages (macOS, Windows, Linux - all architectures)
npm run dist:maximum

# Enhanced build script with 18-core CPU + temp cleanup + bloat prevention
./compile-build-dist.sh

# Platform-specific maximum builds
./compile-build-dist.sh --platform mac      # macOS: Intel + ARM64 + Universal
./compile-build-dist.sh --platform win      # Windows: x64 + x86 + ARM64  
./compile-build-dist.sh --platform linux    # Linux: x64 + ARM64 + ARMv7

# Build options with cleanup control
./compile-build-dist.sh --quick            # Quick build for current platform
./compile-build-dist.sh --no-clean         # Build without cleaning artifacts
./compile-build-dist.sh --no-temp-clean    # Skip system temp cleanup
./compile-build-dist.sh --no-bloat-check   # Skip bloat analysis
```

### Package-Specific Builds (All Installer Types)
```bash
# macOS variants
npm run dist:mac:all        # Intel + ARM64 + Universal (.dmg, .zip, .pkg)
npm run dist:mac:store      # Mac App Store build

# Windows variants  
npm run dist:win:all        # x64 + x86 + ARM64 (all installer types)
npm run dist:win:portable   # Portable executables
npm run dist:win:msi        # MSI installers only

# Linux variants
npm run dist:linux:all      # x64 + ARM64 + ARMv7 (all package formats)
npm run dist:linux:appimage # AppImage only
npm run dist:linux:deb      # Debian packages only
npm run dist:linux:rpm      # RPM packages only
npm run dist:linux:snap     # Snap packages only
npm run dist:linux:tar      # Compressed archives only
```

### Maintenance & Optimization
```bash
# System maintenance
./temp-cleanup.sh           # Clean system temp directories
./bloat-check.sh           # Comprehensive size analysis
npm run temp-clean          # Temp cleanup via npm
npm run bloat-check         # Bloat analysis via npm

# Weekly maintenance routine
npm run temp-clean && npm run bloat-check

# Monthly full maintenance  
./temp-cleanup.sh && ./bloat-check.sh && npm dedupe && npm audit fix
```

### Build Features & Performance
- **18-core CPU parallelism** for maximum build speed
- **Automatic temp cleanup** prevents 110GB+ accumulations  
- **Bloat monitoring** with size optimization recommendations
- **42+ total packages** across all platforms and architectures
- **All installer types**: .dmg, .exe, .msi, .AppImage, .deb, .rpm, .snap, portable, etc.
- **Cross-platform compatibility** with proper cleanup on macOS, Windows, Linux

---

## 🧪 Testing Commands

### Test Swarm Functionality
```bash
# Simple test - single agent
echo "Create a test file 'test.txt' with content about AI development" | claude --model sonnet --verbose --dangerously-skip-permissions -p

# Parallel test - 3 agents
for i in {1..3}; do
    echo "Create test-${i}.txt with unique content about topic ${i}" | claude --model sonnet --verbose --dangerously-skip-permissions -p &
done
wait

# Verify parallel execution worked
ls -la test-*.txt
```

---

## 📁 File Operations

### Batch File Processing
```bash
# Process all Python files in parallel
for file in *.py; do
    echo "Analyze and optimize $file" | claude --model sonnet --verbose --dangerously-skip-permissions -p > "${file%.py}_analysis.txt" &
done
wait

# Process all markdown files
find . -name "*.md" | while read file; do
    echo "Review and improve documentation in $file" | claude --model sonnet --verbose --dangerously-skip-permissions -p > "${file%.md}_improved.md" &
done
wait
```

---

## 🎯 Model Selection Strategy

### When to Use Sonnet vs Opus
```bash
# Sonnet - Fast, excellent quality (DEFAULT)
echo "TASK" | claude --model sonnet --verbose --dangerously-skip-permissions -p

# Opus - Slower, highest quality (FOR SYNTHESIS)
echo "COMPLEX_SYNTHESIS_TASK" | claude --model opus --verbose --dangerously-skip-permissions -p

# Mixed approach - Sonnet for generation, Opus for synthesis
for i in {1..5}; do
    echo "Generate component $i" | claude --model sonnet --verbose --dangerously-skip-permissions -p > comp_$i.txt &
done
wait
cat comp_*.txt > all_components.txt
echo "Synthesize all components into final system" | claude --model opus --verbose --dangerously-skip-permissions -p > final_system.txt
```

---

## 🔄 Session Management

### Check Running Processes
```bash
# See all Claude processes
ps aux | grep claude

# Kill specific process
kill [PID]

# Kill all Claude processes
pkill -f claude
```

### Resume After Interruption
```bash
# Continue from specific checkpoint
echo "Resume from [LAST_COMPLETED_TASK]" | claude --model sonnet --verbose --dangerously-skip-permissions -p
```

---

## 💡 Pro Tips & Tricks

### 1. Output Redirection
```bash
# Append instead of overwrite
echo "TASK" | claude --model sonnet --verbose --dangerously-skip-permissions -p >> cumulative_output.txt

# Capture errors too
echo "TASK" | claude --model sonnet --verbose --dangerously-skip-permissions -p > output.txt 2>&1

# Tee to see output while saving
echo "TASK" | claude --model sonnet --verbose --dangerously-skip-permissions -p | tee output.txt
```

### 2. Variable Substitution
```bash
PROJECT_NAME="MyApp"
FEATURE="authentication"
echo "Implement $FEATURE for $PROJECT_NAME" | claude --model sonnet --verbose --dangerously-skip-permissions -p > "${PROJECT_NAME}_${FEATURE}.txt"
```

### 3. Conditional Swarms
```bash
# Only spawn if file exists
if [ -f "requirements.txt" ]; then
    echo "Analyze Python dependencies" | claude --model sonnet --verbose --dangerously-skip-permissions -p > dep_analysis.txt &
fi
```

### 4. Time Tracking
```bash
# Time a swarm execution
time {
    for i in {1..10}; do
        echo "Task $i" | claude --model sonnet --verbose --dangerously-skip-permissions -p > task_$i.txt &
    done
    wait
}
```

---

## 🆘 SWARM FAILURE RECOVERY

### When Background Commands Return "(No content)"

**Root Cause**: Often indicates Claude Code GUI environment instead of Claude CLI terminal.

#### Immediate Diagnostics
```bash
# 1. Check your environment
which claude
echo $SHELL

# 2. Test basic functionality
echo "test" | claude --model sonnet --verbose --dangerously-skip-permissions -p

# 3. Test background execution
echo "test bg" | claude --model sonnet --verbose --dangerously-skip-permissions -p > bg_test.txt &
wait
cat bg_test.txt
```

#### Recovery Procedures

##### Option 1: Switch to Claude CLI Terminal
```bash
# Exit Claude Code GUI if using it
# Open terminal
# Navigate to project directory
cd /path/to/your/project
# Retry swarm commands
```

##### Option 2: Manual Fallback (Sequential Execution)
```bash
# Instead of parallel (&), run one at a time
echo "TASK_1" | claude --model sonnet --verbose --dangerously-skip-permissions -p > output_1.txt
echo "TASK_2" | claude --model sonnet --verbose --dangerously-skip-permissions -p > output_2.txt
echo "TASK_3" | claude --model sonnet --verbose --dangerously-skip-permissions -p > output_3.txt
# Continue for each task
```

##### Option 3: Interactive Debugging
```bash
# Remove --print flag for interactive mode
echo "TASK_DEBUG" | claude --model sonnet --dangerously-skip-permissions
# See if Claude responds interactively
```

### When Swarms Stall or Hang

#### Stop All Swarms
```bash
# Check what's running
jobs
ps aux | grep claude

# Kill all background jobs
kill %1 %2 %3  # etc for each job number
# OR kill all Claude processes
pkill -f claude
```

#### Restart Individual Swarms
```bash
# Restart specific failed swarms
echo "Restart [SPECIFIC_TASK]" | claude --model sonnet --verbose --dangerously-skip-permissions -p > restart_output.txt
```

### When Directory Structure Missing

#### Create Missing Directories
```bash
# Create all required directories
mkdir -p {dev,docs,src,dist,temp,output}

# Verify write permissions
touch dev/test_write && rm dev/test_write
```

#### Fix Permission Issues
```bash
# Fix directory permissions if needed
chmod 755 {dev,docs,src,dist}
chmod 644 *.txt *.md  # Fix file permissions
```

### When Context Window Fills Up

#### Emergency Context Cleanup
```bash
# Stop all current swarms
pkill -f claude

# Archive completed work
mkdir archive_$(date +%Y%m%d_%H%M)
mv dev/*.txt archive_*/
mv *.md archive_*/

# Restart with clean context
echo "Resume from checkpoint: [LAST_COMPLETED_PHASE]" | claude --model sonnet --verbose --dangerously-skip-permissions -p
```

### When PRD Swarm Fails

#### Individual PRD Components
```bash
# Run each PRD component individually if parallel fails
echo "EXECUTIVE SUMMARY: Create executive summary for [APP_IDEA]" | claude --model sonnet --verbose --dangerously-skip-permissions -p > prd_executive.txt
echo "TECHNICAL ARCHITECTURE: Define tech specs for [APP_IDEA]" | claude --model sonnet --verbose --dangerously-skip-permissions -p > prd_tech.txt
# Continue for each component
```

### When Build Commands Fail

#### Alternative Build Approaches
```bash
# Try simpler build command
npm run build

# Try without parallelism
npm run dist -- --single-process

# Manual step-by-step
npm run compile
npm run package
npm run dist
```

### Environment-Specific Recovery

#### macOS Recovery
```bash
# Update Claude CLI
brew update && brew upgrade claude

# Fix PATH issues
echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

#### Windows Recovery
```bash
# Check Claude CLI installation
where claude
claude --version

# Restart command prompt as administrator if needed
```

#### Linux Recovery
```bash
# Update Claude CLI
sudo apt update && sudo apt upgrade claude
# OR
sudo yum update claude

# Check permissions
ls -la $(which claude)
```

### When All Else Fails

#### Complete Reset Procedure
```bash
# 1. Save current work
cp -r . ../project_backup_$(date +%Y%m%d)

# 2. Reset environment
pkill -f claude
cd ..
rm -rf project_temp_files

# 3. Restart from known good state
cd project_backup_*/
echo "Full system reset - resume from [LAST_KNOWN_GOOD_STATE]" | claude --model sonnet --verbose --dangerously-skip-permissions -p
```

#### Contact Support Checklist
```markdown
When reporting issues, include:
- [ ] Operating system and version
- [ ] Claude CLI version (`claude --version`)
- [ ] Exact command that failed
- [ ] Error message received
- [ ] Contents of failed output files
- [ ] Environment variables (`echo $PATH`)
- [ ] Directory structure (`ls -la`)
```

---

## ⚠️ Common Pitfalls & Solutions

### Pitfall 1: Forgetting & for parallel
```bash
# WRONG - Sequential execution
echo "Task 1" | claude --model sonnet --verbose --dangerously-skip-permissions -p
echo "Task 2" | claude --model sonnet --verbose --dangerously-skip-permissions -p

# RIGHT - Parallel execution
echo "Task 1" | claude --model sonnet --verbose --dangerously-skip-permissions -p &
echo "Task 2" | claude --model sonnet --verbose --dangerously-skip-permissions -p &
wait
```

### Pitfall 2: Missing wait
```bash
# WRONG - Script exits before swarms complete
for i in {1..5}; do
    echo "Task $i" | claude --model sonnet --verbose --dangerously-skip-permissions -p &
done
# Script ends here, swarms might not complete!

# RIGHT - Wait for all to complete
for i in {1..5}; do
    echo "Task $i" | claude --model sonnet --verbose --dangerously-skip-permissions -p &
done
wait
```

### Pitfall 3: Wrong flag order
```bash
# WRONG - Flags in wrong order
echo "Task" | claude --print --model sonnet --dangerously-skip-permissions

# RIGHT - Consistent flag order
echo "Task" | claude --model sonnet --verbose --dangerously-skip-permissions -p
```

---

*These commands have been tested and proven in production*
*Always use --dangerously-skip-permissions for automation*
*The & and wait pattern is critical for parallel execution*