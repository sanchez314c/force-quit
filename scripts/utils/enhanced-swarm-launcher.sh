#!/bin/bash
# Enhanced SWARM Launcher for ForceQUIT Project
# Session: FLIPPED-POLES SWARM Launch

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Global variables - Use persistent session file
SESSION_FILE=".swarm_session"

if [ -f "$SESSION_FILE" ]; then
    # Load existing session
    source "$SESSION_FILE"
else
    # Create new session
    export SWARM_SESSION_ID="FLIPPED-POLES_$(date +%Y%m%d_%H%M%S)"
    echo "export SWARM_SESSION_ID=\"$SWARM_SESSION_ID\"" > "$SESSION_FILE"
fi

export SWARM_LOG_DIR="swarm_logs/${SWARM_SESSION_ID}"
export SWARM_DASHBOARD_LOG="${SWARM_LOG_DIR}/dashboard.log"
export SWARM_ERROR_LOG="${SWARM_LOG_DIR}/errors.log"
export SWARM_PERFORMANCE_LOG="${SWARM_LOG_DIR}/performance.log"
export SWARM_AUDIT_LOG="${SWARM_LOG_DIR}/audit.log"
export AGENT_STATUS_DIR="${SWARM_LOG_DIR}/agents"

echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║                    SWARM 2.0 ENHANCED LOGGING SYSTEM                 ║${NC}"
echo -e "${PURPLE}║                     Mission: ForceQUIT Implementation                ║${NC}"
echo -e "${PURPLE}║                    Launch Codes: FLIPPED-POLES                       ║${NC}"
echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Initialize logging system
init_swarm_logging() {
    mkdir -p "$SWARM_LOG_DIR"
    mkdir -p "$AGENT_STATUS_DIR"
    
    # Create session header
    {
        echo "# SWARM Execution Session: $SWARM_SESSION_ID"
        echo "## Mission: ForceQUIT - Sleek macOS Force Quit Utility"
        echo "## Launch Codes: FLIPPED-POLES"
        echo "## Started: $(date)"
        echo "## Operator: $USER (Jason)"
        echo "## Working Directory: $PWD"
        echo "## Phase: BrainSWARMING - Concept Development"
        echo "## Progress: 0/10 phases complete (0%)"
        echo ""
        echo "## ALL PHASES TO COMPLETE:"
        echo "- [ ] BrainSWARMING - App (STARTING NOW!)"
        echo "- [ ] BrainSWARMING - UI/UX"
        echo "- [ ] Techstack MINISWARM Finalize"
        echo "- [ ] PRD SWARM"
        echo "- [ ] SWARM Build Phases"
        echo "- [ ] CodeFIX SWARM"
        echo "- [ ] Q/C SWARM"
        echo "- [ ] Build-Compile-Dist"
        echo "- [ ] Test"
        echo "- [ ] Feedback"
        echo ""
        echo "## Current Mission: BrainSWARMING - App (PHASE 1)"
        echo "- 🎯 BRAINSTORM ForceQUIT concept from ZERO"
        echo "- 🎯 Generate creative ideas for sleek macOS force quit utility"
        echo "- 🎯 Explore dark mode, avant-garde UI possibilities"
        echo "- 🎯 Think of innovative features and user experience"
        echo ""
    } > "$SWARM_AUDIT_LOG"
    
    # Initialize dashboard
    {
        echo "SWARM Session $SWARM_SESSION_ID initialized"
        echo "Mission: ForceQUIT CodeFIX Implementation"
        echo "Launch Codes: FLIPPED-POLES CONFIRMED"
        echo "Claude Master: Standing by for agent deployment"
        echo ""
    } > "$SWARM_DASHBOARD_LOG"
    
    echo -e "${GREEN}[SWARM-LOG]${NC} Enhanced logging system initialized"
    echo -e "${CYAN}[SWARM-LOG]${NC} Session ID: $SWARM_SESSION_ID"
    echo -e "${CYAN}[SWARM-LOG]${NC} Log Directory: $SWARM_LOG_DIR"
    echo ""
}

# Enhanced agent launcher with comprehensive logging
launch_swarm_agent() {
    local agent_name="$1"
    local agent_task="$2"
    local agent_personality="$3"  # New: Agent personality for enhanced interaction
    
    # Ensure directories exist
    mkdir -p "$SWARM_LOG_DIR"
    mkdir -p "$AGENT_STATUS_DIR"
    
    local agent_id="${agent_name}_$(date +%H%M%S)_$$"
    local agent_log="${AGENT_STATUS_DIR}/${agent_id}.log"
    local agent_output="${AGENT_STATUS_DIR}/${agent_id}_output.txt"
    local agent_errors="${AGENT_STATUS_DIR}/${agent_id}_errors.txt"
    
    # Personalized agent prompt with personality
    local enhanced_prompt="Hey Claude! You're ${agent_name} - ${agent_personality}

    MISSION: ForceQUIT - Sleek macOS Force Quit Utility
    LAUNCH CODES: FLIPPED-POLES
    YOUR ROLE: You're one of Jason's specialized AI agents working on this awesome project!
    
    CONTEXT: This is Phase 1 of a 10-phase SWARM development. We're BRAINSTORMING the concept from scratch!
    
    TASK: ${agent_task}
    
    PERSONALITY: ${agent_personality}
    
    Remember: You're talking to other Claude agents too - we're all working together on this! Be enthusiastic and detailed in your analysis.
    
    End your response with: '---AGENT ${agent_name} COMPLETE---' so we know you're done."
    
    # Log agent launch
    {
        echo "AGENT_LAUNCH|$(date +%Y-%m-%d_%H:%M:%S)|${agent_id}|${agent_name}|STARTING"
        echo "PERSONALITY: $agent_personality"
        echo "TASK: $agent_task"
        echo "---"
    } >> "$SWARM_PERFORMANCE_LOG"
    
    # Create agent status file
    {
        echo "AGENT_ID: $agent_id"
        echo "AGENT_NAME: $agent_name"
        echo "PERSONALITY: $agent_personality"
        echo "STATUS: STARTING"
        echo "START_TIME: $(date +%Y-%m-%d_%H:%M:%S)"
        echo "PID: $$"
        echo "MISSION: ForceQUIT CodeFIX Implementation"
        echo "TASK: $agent_task"
    } > "$agent_log"
    
    echo -e "${BLUE}[AGENT-START]${NC} 🤖 $agent_name"
    echo -e "${CYAN}              ${NC} 💭 $agent_personality"
    
    # Launch agent with comprehensive logging
    (
        echo "STATUS: RUNNING" >> "$agent_log"
        echo "RUN_TIME: $(date +%Y-%m-%d_%H:%M:%S)" >> "$agent_log"
        
        # Execute the actual agent task with enhanced prompt
        echo "$enhanced_prompt" | claude --model sonnet --verbose --dangerously-skip-permissions -p > "$agent_output" 2> "$agent_errors"
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
                echo "PERSONALITY: $agent_personality"
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
    
    echo -e "${GREEN}[AGENT-LAUNCHED]${NC} 🚀 $agent_name (PID: $agent_pid)"
    echo ""
    
    return 0
}

# Export functions and variables
export -f init_swarm_logging
export -f launch_swarm_agent

echo -e "${YELLOW}[SYSTEM]${NC} Enhanced SWARM launcher loaded and ready"
echo -e "${PURPLE}[SYSTEM]${NC} ForceQUIT BRAINSTORMING mission parameters confirmed"
echo ""