# Task Completion Checklist for ForceQUIT

## When Task is Complete - Run These Commands

### 1. Code Quality
- [ ] Format code with SwiftFormat if available
- [ ] Run SwiftLint for style compliance  
- [ ] Check for compiler warnings: `swift build`

### 2. Testing
- [ ] Run unit tests: `swift test`
- [ ] Verify build succeeds: `swift build -c release`
- [ ] Test universal binary: `./compile-build-dist-swift.sh --arch universal`

### 3. Documentation
- [ ] Update relevant documentation files
- [ ] Verify CLAUDE.md is current
- [ ] Check SWARM documentation alignment

### 4. SWARM Protocol
- [ ] Update task list in `/dev/task-list.md`
- [ ] Log completion in SWARM session logs
- [ ] Prepare hand-off documentation for next phase

### 5. Version Control (if requested)
- [ ] Stage changes: `git add .`
- [ ] Commit with descriptive message
- [ ] Verify clean working directory: `git status`

## Success Criteria
- ✅ No compiler warnings or errors
- ✅ All tests pass
- ✅ Documentation updated
- ✅ SWARM protocols followed
- ✅ Performance targets met
- ✅ Security requirements satisfied