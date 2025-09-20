# ForceQUIT Development Commands

## SWARM Framework Commands

### Critical Flags for Automation
```bash
--model sonnet --verbose --dangerously-skip-permissions -p
```

### Basic SWARM Pattern
```bash
echo "TASK_DESCRIPTION" | claude --model sonnet --verbose --dangerously-skip-permissions -p > output.txt
```

### Parallel SWARM Execution
```bash
echo "AGENT_1_TASK" | claude --model sonnet --verbose --dangerously-skip-permissions -p > agent1.txt &
echo "AGENT_2_TASK" | claude --model sonnet --verbose --dangerously-skip-permissions -p > agent2.txt &
echo "AGENT_3_TASK" | claude --model sonnet --verbose --dangerously-skip-permissions -p > agent3.txt &
wait
```

## Swift Build Commands

### Basic Development
```bash
# Basic Swift build (agent-executable)
swift build -c release

# Development testing  
./run-swift-source.sh
```

### Complete Build with Distribution
```bash
# Complete build with distribution (agent-controlled)
./compile-build-dist-swift.sh --config release

# Universal binary build
./compile-build-dist-swift.sh --arch universal --config release

# Signed and notarized build
./compile-build-dist-swift.sh --sign --notarize --dmg
```

## Project Structure Commands
```bash
# Create required directories
mkdir -p {dev,docs,src,dist}

# List project structure
find . -type f -name "*.swift" -o -name "*.md" -o -name "Package.swift"
```

## Darwin System Commands
- `ls`, `cd`, `grep`, `find` - standard Unix commands work on macOS
- `pbcopy`, `pbpaste` - clipboard operations
- `open` - open files/applications
- `say` - text to speech for testing