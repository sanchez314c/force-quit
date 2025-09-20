#!/bin/bash
# Fixed SWARM Brainstorming Launcher
# Mission: ForceQUIT Concept Brainstorming

set -e

echo "🚀 LAUNCHING FIXED BRAINSTORMING SWARM..."

# Source the enhanced launcher
source enhanced-swarm-launcher.sh

# Initialize logging
init_swarm_logging

echo "📋 SESSION INITIALIZED: $SWARM_SESSION_ID"
echo "📁 LOG DIRECTORY: $SWARM_LOG_DIR"
echo ""

# Test single agent first
echo "🧪 TESTING SINGLE AGENT..."
launch_swarm_agent "TEST_AGENT" "Say hello and confirm you received this message. Just respond with 'Hello from TEST_AGENT!' and end with ---AGENT TEST_AGENT COMPLETE---" "Friendly test agent"

# Wait for test
wait

echo ""
echo "✅ TEST COMPLETE - CHECKING OUTPUT..."

# Check if test worked
if [ -f "${AGENT_STATUS_DIR}/TEST_AGENT"*"_output.txt" ]; then
    echo "✅ LOGGING SYSTEM WORKING!"
    echo "📄 Test output:"
    cat "${AGENT_STATUS_DIR}/TEST_AGENT"*"_output.txt"
    echo ""
    echo "🎯 READY FOR FULL BRAINSTORMING SWARM!"
else
    echo "❌ LOGGING SYSTEM STILL BROKEN"
    echo "📁 Directory contents:"
    ls -la "$AGENT_STATUS_DIR/" 2>/dev/null || echo "Directory doesn't exist"
fi