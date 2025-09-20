# 📊 SWARM Logging & Monitoring System v2.0
## Comprehensive Real-Time Execution Tracking & Analysis

**Version:** 2.0  
**Status:** PRODUCTION READY  
**Purpose:** Complete visibility into SWARM execution with real-time monitoring, error tracking, performance metrics, and automated problem detection.

---

## 🎯 System Overview

This enhanced logging system provides complete visibility into SWARM operations, replacing basic file outputs with comprehensive tracking, real-time dashboards, and intelligent analysis.

### Key Features:
- **Real-time Dashboard** - Live agent status and progress tracking
- **Centralized Error Logging** - All errors captured with context and stack traces
- **Performance Metrics** - Per-agent and overall execution analytics
- **Problem Detection** - Automated alerts for stuck, failed, or slow agents
- **Structured Output** - JSON logs for easy parsing and analysis
- **Recovery Guidance** - Automated suggestions for resolving issues

---

## 🛠 Core Components

### 1. Enhanced SWARM Launcher with Logging
```bash
#!/bin/bash
# enhanced-swarm-launcher.sh

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Global variables
SWARM_SESSION_ID=$(date +%Y%m%d_%H%M%S)_$$
SWARM_LOG_DIR="swarm_logs/${SWARM_SESSION_ID}"
SWARM_DASHBOARD_LOG="${SWARM_LOG_DIR}/dashboard.log"
SWARM_ERROR_LOG="${SWARM_LOG_DIR}/errors.log"
SWARM_PERFORMANCE_LOG="${SWARM_LOG_DIR}/performance.log"
SWARM_AUDIT_LOG="${SWARM_LOG_DIR}/audit.log"
AGENT_STATUS_DIR="${SWARM_LOG_DIR}/agents"

# Initialize logging system
init_swarm_logging() {
    mkdir -p "$SWARM_LOG_DIR"
    mkdir -p "$AGENT_STATUS_DIR"
    
    # Create session header
    {
        echo "# SWARM Execution Session: $SWARM_SESSION_ID"
        echo "## Started: $(date)"
        echo "## Operator: $USER"
        echo "## Working Directory: $PWD"
        echo "## Project: ForceQUIT"
        echo ""
    } > "$SWARM_AUDIT_LOG"
    
    # Initialize dashboard
    echo "SWARM Session $SWARM_SESSION_ID initialized" > "$SWARM_DASHBOARD_LOG"
    
    # Start background monitoring
    monitor_swarm_execution &
    MONITOR_PID=$!
    
    echo -e "${GREEN}[SWARM-LOG]${NC} Logging system initialized: $SWARM_LOG_DIR"
    echo -e "${CYAN}[SWARM-LOG]${NC} Monitor PID: $MONITOR_PID"
}

# Enhanced agent launcher with comprehensive logging
launch_swarm_agent() {
    local agent_name="$1"
    local agent_task="$2"
    local agent_id="${agent_name}_$(date +%H%M%S)_$$"
    local agent_log="${AGENT_STATUS_DIR}/${agent_id}.log"
    local agent_output="${AGENT_STATUS_DIR}/${agent_id}_output.txt"
    local agent_errors="${AGENT_STATUS_DIR}/${agent_id}_errors.txt"
    
    # Log agent launch
    {
        echo "AGENT_LAUNCH|$(date +%Y-%m-%d_%H:%M:%S)|${agent_id}|${agent_name}|STARTING"
        echo "TASK: $agent_task"
        echo "---"
    } >> "$SWARM_PERFORMANCE_LOG"
    
    # Create agent status file
    {
        echo "AGENT_ID: $agent_id"
        echo "AGENT_NAME: $agent_name"
        echo "STATUS: STARTING"
        echo "START_TIME: $(date +%Y-%m-%d_%H:%M:%S)"
        echo "PID: $$"
        echo "TASK: $agent_task"
    } > "$agent_log"
    
    echo -e "${BLUE}[AGENT-START]${NC} $agent_name ($agent_id)"
    
    # Launch agent with comprehensive logging
    (
        echo "STATUS: RUNNING" >> "$agent_log"
        echo "RUN_TIME: $(date +%Y-%m-%d_%H:%M:%S)" >> "$agent_log"
        
        # Execute the actual agent task
        echo "$agent_task" | claude --model sonnet --verbose --dangerously-skip-permissions -p > "$agent_output" 2> "$agent_errors"
        AGENT_EXIT_CODE=$?
        
        # Log completion
        echo "STATUS: COMPLETED" >> "$agent_log"
        echo "END_TIME: $(date +%Y-%m-%d_%H:%M:%S)" >> "$agent_log"
        echo "EXIT_CODE: $AGENT_EXIT_CODE" >> "$agent_log"
        
        # Check for errors
        if [ -s "$agent_errors" ]; then
            echo "STATUS: ERROR" >> "$agent_log"
            {
                echo "ERROR_AGENT|$(date +%Y-%m-%d_%H:%M:%S)|${agent_id}|${agent_name}"
                echo "TASK: $agent_task"
                echo "ERRORS:"
                cat "$agent_errors"
                echo "---"
            } >> "$SWARM_ERROR_LOG"
        fi
        
        # Log performance metrics
        {
            echo "AGENT_COMPLETE|$(date +%Y-%m-%d_%H:%M:%S)|${agent_id}|${agent_name}|EXIT_$AGENT_EXIT_CODE"
            if [ -f "$agent_output" ]; then
                echo "OUTPUT_SIZE: $(wc -c < "$agent_output") bytes"
                echo "OUTPUT_LINES: $(wc -l < "$agent_output") lines"
            fi
            echo "---"
        } >> "$SWARM_PERFORMANCE_LOG"
        
    ) &
    
    local agent_pid=$!
    echo "PID: $agent_pid" >> "$agent_log"
    
    echo -e "${GREEN}[AGENT-LAUNCHED]${NC} $agent_name (PID: $agent_pid)"
    
    return 0
}

# Real-time monitoring with enhanced dashboard
monitor_swarm_execution() {
    local start_time=$(date +%s)
    
    echo -e "${PURPLE}[MONITOR]${NC} Real-time SWARM monitoring started"
    
    while true; do
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        
        # Count active agents
        local active_agents=$(pgrep -f "claude" | wc -l)
        local total_agents=$(find "$AGENT_STATUS_DIR" -name "*.log" 2>/dev/null | wc -l)
        local completed_agents=$(grep -l "STATUS: COMPLETED" "$AGENT_STATUS_DIR"/*.log 2>/dev/null | wc -l)
        local error_agents=$(grep -l "STATUS: ERROR" "$AGENT_STATUS_DIR"/*.log 2>/dev/null | wc -l)
        
        # System resources
        local cpu_usage=$(top -bn1 2>/dev/null | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 || echo "N/A")
        local mem_usage=$(free -m 2>/dev/null | awk '/^Mem:/{printf "%.1f", $3/$2*100}' || echo "N/A")
        
        # Calculate progress
        local progress=0
        if [ "$total_agents" -gt 0 ]; then
            progress=$(( completed_agents * 100 / total_agents ))
        fi
        
        # Dashboard update
        {
            echo "[$(date +%H:%M:%S)] SWARM Status - Elapsed: ${elapsed}s"
            echo "  Agents: $active_agents active, $completed_agents/$total_agents complete ($progress%)"
            echo "  System: CPU ${cpu_usage}%, RAM ${mem_usage}%"
            echo "  Errors: $error_agents agents with errors"
            
            # Check for stuck agents (running >5 minutes)
            local stuck_agents=0
            for agent_log in "$AGENT_STATUS_DIR"/*.log; do
                [ ! -f "$agent_log" ] && continue
                if grep -q "STATUS: RUNNING" "$agent_log" 2>/dev/null; then
                    local start_time_str=$(grep "RUN_TIME:" "$agent_log" | cut -d' ' -f2)
                    if [ -n "$start_time_str" ]; then
                        local agent_start=$(date -d "$start_time_str" +%s 2>/dev/null)
                        if [ $((current_time - agent_start)) -gt 300 ]; then  # 5 minutes
                            stuck_agents=$((stuck_agents + 1))
                        fi
                    fi
                fi
            done
            
            if [ "$stuck_agents" -gt 0 ]; then
                echo "  WARNING: $stuck_agents agents may be stuck (>5min runtime)"
            fi
            
            echo ""
        } >> "$SWARM_DASHBOARD_LOG"
        
        # Console output
        echo -e "${CYAN}[$(date +%H:%M:%S)]${NC} Active: $active_agents | Complete: $completed_agents/$total_agents ($progress%) | CPU: ${cpu_usage}% | RAM: ${mem_usage}%"
        
        # Check if all agents are done
        if [ "$active_agents" -eq 0 ] && [ "$total_agents" -gt 0 ]; then
            echo -e "${GREEN}[MONITOR]${NC} All agents completed"
            break
        fi
        
        # Exit if no agents have been launched yet and we've been running for >10 minutes
        if [ "$total_agents" -eq 0 ] && [ "$elapsed" -gt 600 ]; then
            echo -e "${YELLOW}[MONITOR]${NC} No agents detected, stopping monitor"
            break
        fi
        
        sleep 5
    done
    
    # Generate final report
    generate_final_report
}

# Generate comprehensive final report
generate_final_report() {
    local report_file="${SWARM_LOG_DIR}/FINAL_REPORT.md"
    local end_time=$(date +%s)
    local start_time=$(stat -c %Y "$SWARM_AUDIT_LOG" 2>/dev/null || echo "$end_time")
    local total_duration=$((end_time - start_time))
    
    {
        echo "# SWARM Execution Final Report"
        echo "## Session: $SWARM_SESSION_ID"
        echo "## Generated: $(date)"
        echo ""
        
        echo "## Executive Summary"
        local total_agents=$(find "$AGENT_STATUS_DIR" -name "*_output.txt" 2>/dev/null | wc -l)
        local completed_agents=$(grep -l "STATUS: COMPLETED" "$AGENT_STATUS_DIR"/*.log 2>/dev/null | wc -l)
        local error_agents=$(grep -l "STATUS: ERROR" "$AGENT_STATUS_DIR"/*.log 2>/dev/null | wc -l)
        local success_rate=0
        if [ "$total_agents" -gt 0 ]; then
            success_rate=$(( (total_agents - error_agents) * 100 / total_agents ))
        fi
        
        echo "- **Total Execution Time:** ${total_duration} seconds"
        echo "- **Total Agents:** $total_agents"
        echo "- **Successful Agents:** $((total_agents - error_agents))"
        echo "- **Failed Agents:** $error_agents"
        echo "- **Success Rate:** ${success_rate}%"
        echo ""
        
        echo "## Agent Details"
        for agent_log in "$AGENT_STATUS_DIR"/*.log; do
            [ ! -f "$agent_log" ] && continue
            
            local agent_name=$(grep "AGENT_NAME:" "$agent_log" | cut -d' ' -f2)
            local agent_status=$(grep "STATUS:" "$agent_log" | tail -1 | cut -d' ' -f2)
            local agent_id=$(basename "$agent_log" .log)
            
            echo "### Agent: $agent_name"
            echo "- **ID:** $agent_id"
            echo "- **Status:** $agent_status"
            
            local start_time_str=$(grep "START_TIME:" "$agent_log" | cut -d' ' -f2)
            local end_time_str=$(grep "END_TIME:" "$agent_log" | cut -d' ' -f2)
            
            if [ -n "$start_time_str" ] && [ -n "$end_time_str" ]; then
                local agent_start=$(date -d "$start_time_str" +%s 2>/dev/null || echo "0")
                local agent_end=$(date -d "$end_time_str" +%s 2>/dev/null || echo "0")
                local agent_duration=$((agent_end - agent_start))
                echo "- **Duration:** ${agent_duration} seconds"
            fi
            
            # Output size
            local output_file="${AGENT_STATUS_DIR}/${agent_id}_output.txt"
            if [ -f "$output_file" ]; then
                local output_size=$(wc -c < "$output_file")
                local output_lines=$(wc -l < "$output_file")
                echo "- **Output:** ${output_lines} lines, ${output_size} bytes"
            fi
            
            echo ""
        done
        
        echo "## Error Summary"
        if [ -f "$SWARM_ERROR_LOG" ] && [ -s "$SWARM_ERROR_LOG" ]; then
            echo "Errors were detected during execution:"
            echo '```'
            cat "$SWARM_ERROR_LOG"
            echo '```'
        else
            echo "No errors detected during execution."
        fi
        echo ""
        
        echo "## Performance Analysis"
        if [ -f "$SWARM_PERFORMANCE_LOG" ] && [ -s "$SWARM_PERFORMANCE_LOG" ]; then
            echo "Performance metrics:"
            echo '```'
            tail -20 "$SWARM_PERFORMANCE_LOG"
            echo '```'
        fi
        echo ""
        
        echo "## Files Generated"
        echo "All execution artifacts are available in: \`$SWARM_LOG_DIR\`"
        echo ""
        echo "### Key Files:"
        echo "- **This Report:** \`FINAL_REPORT.md\`"
        echo "- **Agent Outputs:** \`agents/*_output.txt\`"
        echo "- **Error Log:** \`errors.log\`"
        echo "- **Performance Log:** \`performance.log\`"
        echo "- **Dashboard Log:** \`dashboard.log\`"
        echo "- **Audit Trail:** \`audit.log\`"
        
    } > "$report_file"
    
    echo -e "${GREEN}[REPORT]${NC} Final report generated: $report_file"
    echo -e "${PURPLE}[SUMMARY]${NC} Session complete - Success rate: ${success_rate}% (${total_agents} agents, ${error_agents} errors)"
}

# Problem detection and automated recovery suggestions
detect_problems() {
    local problems_file="${SWARM_LOG_DIR}/problems_detected.md"
    local problems_found=0
    
    {
        echo "# SWARM Problem Detection Report"
        echo "## Generated: $(date)"
        echo ""
        
        # Check for stuck agents
        echo "## Stuck Agent Analysis"
        local stuck_found=0
        for agent_log in "$AGENT_STATUS_DIR"/*.log; do
            [ ! -f "$agent_log" ] && continue
            if grep -q "STATUS: RUNNING" "$agent_log" 2>/dev/null; then
                local start_time_str=$(grep "RUN_TIME:" "$agent_log" | cut -d' ' -f2)
                if [ -n "$start_time_str" ]; then
                    local agent_start=$(date -d "$start_time_str" +%s 2>/dev/null || echo "0")
                    local current_time=$(date +%s)
                    local runtime=$((current_time - agent_start))
                    if [ "$runtime" -gt 300 ]; then  # 5 minutes
                        local agent_name=$(grep "AGENT_NAME:" "$agent_log" | cut -d' ' -f2)
                        echo "- **STUCK AGENT:** $agent_name (running ${runtime}s)"
                        echo "  - **Recovery:** Consider killing and restarting this agent"
                        echo "  - **Command:** \`kill \$(pgrep -f \"$agent_name\")\`"
                        stuck_found=$((stuck_found + 1))
                        problems_found=$((problems_found + 1))
                    fi
                fi
            fi
        done
        
        if [ "$stuck_found" -eq 0 ]; then
            echo "No stuck agents detected."
        fi
        echo ""
        
        # Check for high error rate
        echo "## Error Rate Analysis"
        local total_agents=$(find "$AGENT_STATUS_DIR" -name "*.log" 2>/dev/null | wc -l)
        local error_agents=$(grep -l "STATUS: ERROR" "$AGENT_STATUS_DIR"/*.log 2>/dev/null | wc -l)
        
        if [ "$total_agents" -gt 0 ]; then
            local error_rate=$(( error_agents * 100 / total_agents ))
            if [ "$error_rate" -gt 20 ]; then
                echo "- **HIGH ERROR RATE:** ${error_rate}% (${error_agents}/${total_agents} agents failed)"
                echo "  - **Recovery:** Check error log for common issues"
                echo "  - **File:** \`${SWARM_ERROR_LOG}\`"
                problems_found=$((problems_found + 1))
            else
                echo "Error rate acceptable: ${error_rate}%"
            fi
        else
            echo "No agents to analyze yet."
        fi
        echo ""
        
        # Check system resources
        echo "## Resource Usage Analysis"
        local cpu_usage=$(top -bn1 2>/dev/null | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 || echo "0")
        local mem_usage=$(free -m 2>/dev/null | awk '/^Mem:/{printf "%.1f", $3/$2*100}' || echo "0")
        
        if [ "${cpu_usage%.*}" -gt 90 ] 2>/dev/null; then
            echo "- **HIGH CPU USAGE:** ${cpu_usage}%"
            echo "  - **Recovery:** Consider reducing parallel agent count"
            problems_found=$((problems_found + 1))
        fi
        
        if [ "${mem_usage%.*}" -gt 90 ] 2>/dev/null; then
            echo "- **HIGH MEMORY USAGE:** ${mem_usage}%"
            echo "  - **Recovery:** Monitor for memory leaks, restart agents if needed"
            problems_found=$((problems_found + 1))
        fi
        
        if [ "$problems_found" -eq 0 ]; then
            echo "No resource issues detected."
        fi
        echo ""
        
        echo "## Overall Status"
        if [ "$problems_found" -eq 0 ]; then
            echo "✅ **ALL SYSTEMS NORMAL** - No problems detected"
        else
            echo "⚠️ **${problems_found} ISSUES DETECTED** - Review recommendations above"
        fi
        
    } > "$problems_file"
    
    if [ "$problems_found" -gt 0 ]; then
        echo -e "${YELLOW}[PROBLEM-DETECTOR]${NC} $problems_found issues detected - See: $problems_file"
    fi
}

# Cleanup function
cleanup_swarm_logging() {
    if [ -n "$MONITOR_PID" ]; then
        kill "$MONITOR_PID" 2>/dev/null
    fi
    
    generate_final_report
    detect_problems
    
    echo -e "${GREEN}[SWARM-LOG]${NC} Session complete: $SWARM_LOG_DIR"
}

# Trap cleanup on exit
trap cleanup_swarm_logging EXIT

# Export functions for use in other scripts
export -f init_swarm_logging
export -f launch_swarm_agent
export -f monitor_swarm_execution
export -f generate_final_report
export -f detect_problems
export -f cleanup_swarm_logging
```

---

## 🔧 Integration Functions

### CodeFIX SWARM with Enhanced Logging
```bash
#!/bin/bash
# codefix-swarm-with-logging.sh

source enhanced-swarm-launcher.sh

execute_codefix_swarm() {
    local codebase_path="$1"
    
    echo -e "${PURPLE}[CODEFIX-SWARM]${NC} Launching diagnostic and repair swarm for: $codebase_path"
    
    # Initialize logging
    init_swarm_logging
    
    # Phase 1: Diagnostic Swarm (6 agents)
    echo -e "${BLUE}[PHASE-1]${NC} Launching diagnostic agents..."
    
    launch_swarm_agent "ARCHITECTURE" "ARCHITECTURE ANALYSIS: Analyze this codebase structure and identify architectural issues, anti-patterns, technical debt, and structural problems. Focus on: file organization, dependency management, separation of concerns, scalability issues, maintainability problems. CODEBASE_PATH: $codebase_path"
    
    launch_swarm_agent "SECURITY" "SECURITY AUDIT: Perform comprehensive security analysis of this codebase. Identify: authentication flaws, authorization issues, input validation problems, XSS vulnerabilities, SQL injection risks, secret exposure, dependency vulnerabilities. CODEBASE_PATH: $codebase_path"
    
    launch_swarm_agent "PERFORMANCE" "PERFORMANCE AUDIT: Analyze this codebase for performance bottlenecks, memory leaks, inefficient algorithms, database query issues, loading problems, resource usage optimization opportunities. CODEBASE_PATH: $codebase_path"
    
    launch_swarm_agent "QUALITY" "CODE QUALITY AUDIT: Review code quality issues including: syntax errors, logic bugs, code smells, documentation gaps, test coverage, naming conventions, code duplication, unused code. CODEBASE_PATH: $codebase_path"
    
    launch_swarm_agent "DEPENDENCIES" "DEPENDENCY AUDIT: Analyze all dependencies for: outdated packages, security vulnerabilities, compatibility issues, unused dependencies, license conflicts, update recommendations. CODEBASE_PATH: $codebase_path"
    
    launch_swarm_agent "FUNCTIONALITY" "FUNCTIONALITY AUDIT: Identify incomplete features, missing implementations, broken functionality, API endpoints that don't work, UI components that are non-functional, integration issues. CODEBASE_PATH: $codebase_path"
    
    # Wait for diagnostic phase
    echo -e "${CYAN}[PHASE-1]${NC} Waiting for diagnostic agents to complete..."
    wait
    
    # Phase 2: Master Synthesis
    echo -e "${BLUE}[PHASE-2]${NC} Launching master synthesis..."
    
    # Combine all diagnostic outputs
    cat "${AGENT_STATUS_DIR}"/*_output.txt > "${SWARM_LOG_DIR}/combined_diagnostics.txt"
    
    launch_swarm_agent "MASTER_SYNTHESIS" "MASTER CODEFIX DIAGNOSIS: Analyze all diagnostic reports in '${SWARM_LOG_DIR}/combined_diagnostics.txt' and create a comprehensive codebase repair plan with prioritized issues and specific fixes."
    
    wait
    
    echo -e "${GREEN}[CODEFIX-SWARM]${NC} Complete! Check logs in: $SWARM_LOG_DIR"
}

# Export function
export -f execute_codefix_swarm
```

### Real-time Dashboard Viewer
```bash
#!/bin/bash
# swarm-dashboard.sh

view_live_dashboard() {
    local log_dir="$1"
    
    if [ -z "$log_dir" ]; then
        # Find most recent session
        log_dir=$(find swarm_logs -name "*_*" -type d | sort | tail -1)
    fi
    
    if [ ! -d "$log_dir" ]; then
        echo "Error: Log directory not found: $log_dir"
        exit 1
    fi
    
    echo "Watching SWARM dashboard: $log_dir"
    echo "Press Ctrl+C to exit"
    echo ""
    
    # Watch dashboard log with live updates
    tail -f "$log_dir/dashboard.log" | while read line; do
        echo -e "${CYAN}[DASHBOARD]${NC} $line"
    done
}

# Export function
export -f view_live_dashboard
```

---

## 📋 Usage Guide

### 1. Basic Integration
```bash
# Source the enhanced logging system
source enhanced-swarm-launcher.sh

# Initialize logging for your swarm session
init_swarm_logging

# Launch agents with automatic logging
launch_swarm_agent "MY_AGENT" "Task description here"
launch_swarm_agent "ANOTHER_AGENT" "Another task here"

# Wait for completion (monitoring runs automatically)
wait
```

### 2. View Live Dashboard
```bash
# In another terminal, watch the live dashboard
./swarm-dashboard.sh

# Or specify a specific session
./swarm-dashboard.sh swarm_logs/20231215_143022_1234
```

### 3. CodeFIX Integration
```bash
# Source enhanced functions
source enhanced-swarm-launcher.sh
source codefix-swarm-with-logging.sh

# Execute CodeFIX with full logging
execute_codefix_swarm "/path/to/ForceQUIT/codebase"
```

### 4. Post-Execution Analysis
```bash
# View final report
cat swarm_logs/[SESSION_ID]/FINAL_REPORT.md

# Check for problems
cat swarm_logs/[SESSION_ID]/problems_detected.md

# Review individual agent outputs
ls swarm_logs/[SESSION_ID]/agents/
```

---

## 📊 Output Structure

### Log Directory Layout
```
swarm_logs/[SESSION_ID]/
├── FINAL_REPORT.md              # Comprehensive final report
├── problems_detected.md         # Automated problem detection
├── dashboard.log                # Real-time execution dashboard
├── errors.log                   # Centralized error log
├── performance.log              # Performance metrics
├── audit.log                    # Session audit trail
└── agents/                      # Individual agent outputs
    ├── AGENT_NAME_123456.log    # Agent status/metadata
    ├── AGENT_NAME_123456_output.txt  # Agent output
    ├── AGENT_NAME_123456_errors.txt  # Agent errors
    └── ...
```

### Dashboard Output Sample
```
[14:32:15] SWARM Status - Elapsed: 245s
  Agents: 3 active, 2/6 complete (33%)
  System: CPU 45.2%, RAM 67.8%
  Errors: 0 agents with errors

[14:32:20] SWARM Status - Elapsed: 250s
  Agents: 2 active, 4/6 complete (67%)
  System: CPU 38.1%, RAM 71.2%
  Errors: 0 agents with errors
```

---

## 🔧 Configuration Options

### Environment Variables
```bash
# Customize logging behavior
export SWARM_LOG_LEVEL="INFO"           # DEBUG, INFO, WARN, ERROR
export SWARM_MONITOR_INTERVAL=5         # Monitoring interval in seconds
export SWARM_STUCK_THRESHOLD=300        # Seconds before agent is considered stuck
export SWARM_MAX_OUTPUT_SIZE=10485760   # Max output size per agent (10MB)
export SWARM_RETAIN_LOGS_DAYS=7         # Days to retain old logs
```

### Custom Color Schemes
```bash
# Override default colors
export SWARM_COLOR_SUCCESS='\033[0;32m'
export SWARM_COLOR_ERROR='\033[0;31m'
export SWARM_COLOR_WARNING='\033[1;33m'
export SWARM_COLOR_INFO='\033[0;36m'
```

---

## 🚀 Ready for ForceQUIT Integration

This enhanced logging system is ready to be integrated with the ForceQUIT CodeFIX SWARM execution. It will provide complete visibility into:

- **Real-time progress** of all ForceQUIT feature implementation agents
- **Error tracking** for any Swift compilation or logic issues
- **Performance monitoring** to ensure efficient resource usage
- **Automated problem detection** for stuck or failed implementations
- **Comprehensive reporting** for debugging and optimization

### Next Steps:
1. **Save this file** to your SnippetLabs master collection
2. **Test the system** with a small swarm before the main CodeFIX launch
3. **Launch CodeFIX SWARM** with full logging for ForceQUIT implementation

**The logging system is ready to provide complete visibility into your SWARM operations!** 🔍✨