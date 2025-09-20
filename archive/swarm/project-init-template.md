# 🚀 PROJECT INITIALIZATION TEMPLATE
## Copy This For Every New Project

---

## 📋 Pre-Flight Checklist

### Critical Execution Pattern Setup
- [ ] **Directory structure created FIRST**
  ```bash
  mkdir -p {dev,docs,src,dist} && ls -la
  ```
- [ ] **Understand the WAIT command requirement**
  ```bash
  # This pattern MUST include 'wait' command:
  echo "test" | claude --model sonnet --verbose --dangerously-skip-permissions -p > dev/test.txt 2>&1 &
  wait  # <- CRITICAL: Don't skip this
  ls -la dev/  # Verify file creation
  ```

### Project Setup
- [ ] Project folder created
- [ ] Swarm documentation copied to /docs
- [ ] Claude Code CLI ready (`claude --version`)
- [ ] Sequential Thinking MCP available (if needed)

### Execution Pattern Understanding
- [ ] **Know that `(No content)` from backgrounded commands is NORMAL**
- [ ] **Always include `wait` after parallel commands**  
- [ ] **Always verify results with `ls -la dev/`**
- [ ] **Use `2>&1` to capture errors**

### Pre-Flight Knowledge Check
- ✅ **I understand**: Background commands (`&`) return immediately 
- ✅ **I understand**: Must use `wait` to synchronize
- ✅ **I understand**: Check files, not command output
- ✅ **I understand**: The test failure was missing `wait`, not environment

---

## 🎯 Mission Briefing Template

```
Hey Claude, we're starting [PROJECT_NAME] below is our master task list, 
write this out to task-list.md in /dev please.

Project Type: [SELECT ONE]
- [ ] New greenfield application
- [ ] Reviving dead codebase
- [ ] Modernizing legacy system
- [ ] Feature addition to existing app

Technology Stack: [SPECIFY]
- Platform: [Desktop/Web/Mobile/CLI]
- Language: [TypeScript/Python/Swift/etc]
- Framework: [Electron/React/Django/etc]
- Database: [SQLite/PostgreSQL/MongoDB/etc]

All code and PRDs, docs, etc will need to be [created/ingested].

We will check in after each SWARM execution.
Remember to use Sequential Thinking MCP.

As a reminder, here is your MASTER SWARM Directive:
docs/MASTER-SWARM-PROMPT.md

Additional Context:
[ANY PROJECT-SPECIFIC REQUIREMENTS OR CONSTRAINTS]

Confirm everything and respond with any questions,
then I will give you the launch codes for the first CodeSWARM.
```

---

## ✅ Master Task List

```markdown
## Project: [PROJECT_NAME]
## Type: [New Build/Revival/Modernization]
## Stack: [Technology Stack]
## Status: Phase 0 - Initialization
## Date Started: [DATE]
## Target Completion: [DATE]

### Phase 1: Conceptualization
[ ] BrainSWARMING - App
    - [ ] Core concept definition
    - [ ] Problem statement
    - [ ] Solution architecture
    - [ ] Success metrics
    
[ ] BrainSWARMING - UI/UX
    - [ ] User personas
    - [ ] User journey mapping
    - [ ] Interface design language
    - [ ] Component hierarchy
    - [ ] Accessibility requirements

### Phase 2: Technical Planning    
[ ] Techstack NanoSWARM Finalize
    - [ ] Framework selection and justification
    - [ ] Core dependencies
    - [ ] Development tools
    - [ ] Build configuration
    - [ ] Deployment strategy
    
[ ] PRD SWARM
    - [ ] Executive summary generation
    - [ ] Technical specifications
    - [ ] Feature requirements (MoSCoW)
    - [ ] Competitive analysis
    - [ ] Implementation timeline
    - [ ] Success metrics

### Phase 3: Implementation
[ ] SWARM Build Phases
    - [ ] Phase 1: Project structure and boilerplate
    - [ ] Phase 2: Core functionality
    - [ ] Phase 3: Feature implementation
    - [ ] Phase 4: Integration
    - [ ] Phase 5: Polish and optimization

### Phase 4: Quality Assurance    
[ ] CodeFIX SWARM
    - [ ] Diagnostic scan (6 agents)
    - [ ] Critical security fixes
    - [ ] Functionality repairs
    - [ ] Performance optimizations
    - [ ] Dependency updates
    
[ ] Q/C SWARM
    - [ ] Code quality validation
    - [ ] Security audit
    - [ ] Performance benchmarking
    - [ ] Accessibility compliance
    - [ ] Cross-platform testing

### Phase 5: Deployment Preparation    
[ ] Build-Compile-Dist
    - [ ] Development builds
    - [ ] Production optimization
    - [ ] Multi-platform packages
    - [ ] Installer creation
    - [ ] Distribution preparation
    
[ ] Test
    - [ ] Unit test execution
    - [ ] Integration testing
    - [ ] End-to-end testing
    - [ ] User acceptance testing
    - [ ] Performance testing

### Phase 6: Launch    
[ ] Feedback
    - [ ] Internal team review
    - [ ] Beta user testing
    - [ ] Bug tracking setup
    - [ ] Iteration planning
    - [ ] Launch preparation

### Completion Metrics
- [ ] All tests passing (100% of critical, 90%+ of total)
- [ ] Performance targets met
- [ ] Security scan clean
- [ ] Documentation complete
- [ ] Deployment packages created
- [ ] User feedback incorporated
```

---

## 🚀 Launch Codes

### First Launch (After Mission Briefing Confirmed)
```
SWARM LAUNCH CODES: ALPHA-GENESIS
LAUNCH APPROVED.
YOU ARE GO FOR SWARM LAUNCH CLAUDE.
INITIATE BrainSWARMING - App.
LAUNCH SWARM.
```

### Subsequent Launches
```
SWARM LAUNCH CODES: [CODEWORD]
LAUNCH APPROVED.
CONTINUE WITH [SWARM_NAME].
LAUNCH SWARM.
```

### Emergency Abort
```
ABORT ABORT ABORT
ALL SWARMS STAND DOWN
CHECKPOINT CURRENT STATE
AWAIT FURTHER INSTRUCTIONS
```

---

## 📊 Progress Tracking

### Time Estimates (Based on Proven Results)
- **BrainSWARMING**: 10-15 minutes total
- **Tech Stack**: 5 minutes
- **PRD Generation**: 15-20 minutes
- **Build Phases**: 30-60 minutes
- **CodeFIX**: 7-15 minutes
- **Q/C**: 10-15 minutes
- **Build/Compile**: 5-10 minutes
- **Testing**: 10-20 minutes
- **TOTAL**: 90-180 minutes typical

### Success Indicators
- Files being created in correct directories ✅
- Multiple .txt files appearing from swarms ✅
- Terminal showing parallel execution ✅
- task-list.md being updated ✅
- No red error messages ✅
- Context window < 20% used ✅

### Warning Signs
- No file creation after 2 minutes ⚠️
- Repeated clarification requests ⚠️
- Context window > 50% ⚠️
- Terminal completely frozen ⚠️

---

## 💾 Checkpoint System

### After Each Phase
```
Claude, checkpoint current state:
- What's completed: [LIST]
- What's in progress: [LIST]
- What's next: [LIST]
- Any blockers: [LIST]

Save checkpoint to: dev/checkpoint-[PHASE]-[TIMESTAMP].md
```

### Resume From Checkpoint
```
Claude, resume from checkpoint:
- Load: dev/checkpoint-[PHASE]-[TIMESTAMP].md
- Verify state
- Continue with: [NEXT_SWARM]
```

---

## 📝 Project-Specific Customizations

### For Web Applications
```
Additional Requirements:
- SEO optimization required
- Mobile-first responsive design
- PWA capabilities
- Analytics integration
- CDN deployment ready
```

### For Desktop Applications
```
Additional Requirements:
- Native OS integration
- Auto-update system
- Code signing setup
- Installer customization
- Tray/dock functionality
```

### For CLI Tools
```
Additional Requirements:
- Comprehensive --help system
- Man page generation
- Shell completion scripts
- Cross-platform path handling
- Homebrew/apt/yum packaging
```

### For Mobile Apps
```
Additional Requirements:
- App store compliance
- Push notification system
- Offline functionality
- Deep linking support
- Crash reporting integration
```

---

## 🔧 Troubleshooting Commands

### If Swarm Stalls
```bash
# Check what's running
ps aux | grep claude

# Gentle resume
echo "Continue with current task" | claude --model sonnet --verbose --dangerously-skip-permissions -p

# Force restart specific swarm
echo "Restart [SWARM_NAME] from beginning" | claude --model sonnet --verbose --dangerously-skip-permissions -p
```

### If Context Window Fills
```
Claude, we need to optimize context:
1. Summarize current state
2. Archive completed phases to files
3. Keep only active phase in context
4. Continue with reduced context
```

---

## 🎯 Final Checklist Before Launch

- [ ] All documentation in /docs folder
- [ ] task-list.md created in /dev
- [ ] .gitignore configured
- [ ] README.md outlined
- [ ] License selected
- [ ] Version control initialized

---

## 🚦 GO/NO-GO Decision

### GO Criteria
- Clear project requirements ✅
- Technology stack decided ✅
- Time allocated (3+ hours) ✅
- Swarm docs accessible ✅
- Claude Code operational ✅

### NO-GO Criteria
- Unclear requirements ❌
- Technology stack uncertain ❌
- Less than 2 hours available ❌
- Missing swarm documentation ❌
- Claude Code issues ❌

---

**WHEN ALL SYSTEMS ARE GO:**

"ALL SYSTEMS GREEN. 
SWARMS STANDING BY.
AWAITING LAUNCH CODES."

---

*Template Version: 1.0*
*Last Updated: [DATE]*
*Project: [PROJECT_NAME]*