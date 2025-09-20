# 🚀 UNIFIED PROJECT STANDARDIZATION PROMPT - COMPLETE SYNTHESIS

## Quick Usage
Paste this entire document to Claude when in any project folder to standardize it according to best practices.

---

## INSTRUCTION TO CLAUDE

You are about to standardize a project folder structure. Follow these steps EXACTLY and manually organize files based on intelligent analysis of their content and purpose.

---

```markdown
## 🔴 PHASE 0: PROJECT-LEVEL ARCHIVING - ABSOLUTELY CRITICAL 🔴

# ⚠️ ABSOLUTELY CRITICAL ⚠️
# NEVER SKIP THIS PHASE - NO EXCEPTIONS
# CREATE ARCHIVE BEFORE ANY MODIFICATION
# IF YOU FORGET THIS EVEN ONCE, STOP IMMEDIATELY

### 0.1 Local Archive Protocol
**🚨 CRITICAL REQUIREMENT 🚨**: Before ANY modification to the project, create a local archive  
**🚨 NO EXCEPTIONS 🚨**: Even if the project is empty, broken, or tiny - ARCHIVE IT FIRST  
**🚨 VERIFICATION REQUIRED 🚨**: Must verify archive exists before proceeding

**Archive Structure**:
```
project-root/
├── backup/                                  # Backup folder
│   └── backup_[YYYYMMDD_HHMMSS]/          # Complete copy of original state
└── [working files]                         # Files we'll be modifying
```

### 0.2 Archive Creation Process

#### 🛑 STOP AND READ 🛑
**YOU MUST DO THIS BEFORE ANY MODIFICATIONS**  
**DO NOT PROCEED WITHOUT ARCHIVING**  
**THIS IS NOT OPTIONAL**

```bash
# Navigate to the project directory
cd project-root

# 1. Create backup folder
mkdir -p backup

# 2. Create timestamped backup directory
BACKUP_DIR="backup/backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# 3. Copy everything except backup and dist folders
rsync -av --exclude='backup' --exclude='dist' --exclude='node_modules' --exclude='.git' . "$BACKUP_DIR/"

# Alternative using cp (if rsync not available):
# cp -R . "$BACKUP_DIR" 2>/dev/null || true
# rm -rf "$BACKUP_DIR/backup" "$BACKUP_DIR/dist" "$BACKUP_DIR/node_modules" "$BACKUP_DIR/.git"

# 4. Verify the backup was created
ls -la backup/

# 5. Verify the backup contains files
ls -la "$BACKUP_DIR" | head -20
```

### 0.3 Archive Verification
Before proceeding with ANY modifications:
1. Verify backup folder exists: `backup/`
2. Verify timestamped backup directory exists: `backup/backup_[timestamp]/`
3. Verify backup contains actual files (not empty)

### 0.4 Archive .gitignore Addition
Add to .gitignore:
```gitignore
# Local backup archives
backup/
```

### 0.5 Simple Restoration Process
If you need to restore:
```bash
# 1. Navigate to project
cd project-root

# 2. Find the backup you want to restore
ls -la backup/

# 3. Remove current files (except backup folder)
find . -maxdepth 1 ! -name 'backup' ! -name '.' -exec rm -rf {} \;

# 4. Copy files back from backup
LATEST_BACKUP=$(ls -t backup/ | head -1)
cp -R backup/$LATEST_BACKUP/* .
cp -R backup/$LATEST_BACKUP/.[^.]* . 2>/dev/null || true

# 5. Remove the backup folder if desired
rm -rf backup/
```

---

## PHASE 1: DISCOVERY & ANALYSIS (Do First)

### 1.1 Initial Discovery Commands
```bash
# 1. Confirm current directory
pwd

# 2. See current structure
ls -la

# 3. Check for tech stack indicators
ls *.json *.txt *.toml *.swift *.xml *.gradle 2>/dev/null

# 4. Look for source files
find . -type f \( -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.jsx" -o -name "*.tsx" -o -name "*.swift" \) | head -20

# 5. Check for existing documentation
find . -name "*.md" -type f | head -20
```

### 1.2 Technology Stack Detection Rules

**Python Projects:**
- Look for: `*.py` files, `requirements.txt`, `setup.py`, `pyproject.toml`, `Pipfile`
- GUI indicators: imports of `tkinter`, `customtkinter`, `PyQt`, `Kivy`
- Framework indicators: `django`, `flask`, `fastapi` in dependencies
- Data Science: `jupyter` notebooks, `pandas`, `numpy`, `matplotlib` imports

**Node.js Projects:**
- Look for: `package.json`, `node_modules/`, `*.js` files with `require()` or ES6 imports
- Framework indicators: `express`, `nest`, `koa`, `hapi` in dependencies
- Build tools: `webpack.config.js`, `vite.config.js`, `rollup.config.js`

**TypeScript Projects:**
- Look for: `tsconfig.json`, `*.ts` files, `@types/` packages in dependencies
- Combined with Node.js or frontend framework indicators

**Electron Projects:**
- Look for: `electron` in dependencies, `main.js` or `electron.js`, preload scripts
- Combined with both Node.js backend and frontend technologies

**React Projects:**
- Look for: `react` in dependencies, `*.jsx` or `*.tsx` files, React imports
- Build tools: Create React App, Next.js, Vite with React

**Swift Projects:**
- Look for: `*.swift` files, `Package.swift`, `*.xcodeproj`, `*.xcworkspace`
- iOS indicators: UIKit, SwiftUI imports, iOS deployment targets
- macOS indicators: AppKit imports, macOS deployment targets

**HTML/CSS/JS Projects:**
- Look for: `index.html`, standalone CSS/JS without package managers
- Modern variants: ES6 modules, CSS preprocessors, build tools

### 1.3 Create Technology Stack Documentation (CREATE FIRST)

Create `/tech-stack.md`:
```markdown
# Technology Stack

## Core Technologies
- **Language**: [Detected language]
- **Framework**: [Detected framework]  
- **Runtime**: [Node.js/Python/etc version]
- **Package Manager**: [npm/yarn/pip/etc]

## Key Dependencies
[List main dependencies found]

## Development Tools
- **Linter**: [ESLint/Pylint/etc]
- **Formatter**: [Prettier/Black/etc]
- **Testing**: [Jest/Pytest/etc]
- **Build Tool**: [Webpack/Vite/etc]

## Project Type
[Web App/Desktop App/CLI Tool/Library/etc]
```

---

## PHASE 2: UNIVERSAL FOLDER STRUCTURE (Apply to ALL Projects)

### 2.1 Standard Directory Structure (Single or Multi-Version)

```
project-root/
├── .github/
│   ├── workflows/
│   │   └── ci.yml
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md
│   │   └── feature_request.md
│   └── PULL_REQUEST_TEMPLATE.md
├── archive/                   # Old versions, deprecated code
├── assets/                    # Images, icons, media files
│   ├── icons/                 # Application icons (icon.png, icon.ico, etc.)
│   │   ├── icon.icns         # macOS icon (1024x1024)
│   │   ├── icon.ico          # Windows icon (256x256)
│   │   ├── 16x16.png
│   │   ├── 32x32.png
│   │   ├── 48x48.png
│   │   ├── 64x64.png
│   │   ├── 128x128.png
│   │   ├── 256x256.png
│   │   └── 512x512.png
│   ├── images/
│   └── screenshots/
├── backup/                    # Local archives (from Phase 0)
├── config/                    # Configuration files
├── data/                      # Data files (if applicable)
│   ├── raw/                   # Original data
│   ├── processed/             # Transformed data
│   └── final/                 # Analysis-ready data
├── dev/                       # Development resources
│   ├── PRDs/                  # Product requirement docs (if they exist)
│   ├── specs/                 # Technical specifications
│   ├── notes/                 # Development notes
│   └── research/              # Research materials
├── dist/                      # Distribution/deployment files (see Required Structure below)
├── docs/                      # Documentation
│   ├── api/                   # API documentation
│   ├── guides/                # User guides
│   ├── technical/             # Technical docs
│   │   ├── architecture.md
│   │   └── deployment/
│   ├── development/           # Developer guides
│   ├── internal/              # Internal docs
│   └── legacy/                # Archived docs
├── examples/                  # Usage examples
├── scripts/                   # Build and utility scripts
│   ├── compile-build-dist.sh # Main build script
│   ├── build/                 # Build-related scripts
│   ├── deploy/                # Deployment scripts
│   └── utils/                 # Utility scripts
├── src/                       # Source code (varies by stack)
├── tests/                     # Test files
│   ├── unit/
│   ├── integration/
│   └── e2e/
├── tools/                     # Development tools
├── versions/                  # ONLY for multi-version projects
│   ├── v00/                   # Oldest version
│   │   ├── README.md
│   │   ├── CHANGES.md
│   │   └── [v00 code]
│   └── v01/                   # Next version
├── shared/                    # Shared resources (multi-version only)
│
├── run-source-macos.sh        # Run from source on macOS
├── run-source-windows.bat     # Run from source on Windows
├── run-source-linux.sh        # Run from source on Linux
├── run-macos.sh              # Run compiled macOS binary
├── run-windows.bat           # Run compiled Windows binary
├── run-linux.sh              # Run compiled Linux binary
├── runProject.sh             # Version selector (multi-version only)
├── setup.sh                  # Setup script
│
├── .env.example              # Environment variables template
├── .gitignore               # Git ignore rules
├── .gitattributes           # Git file attributes
├── CHANGELOG.md             # Version history (move to dev/ after creation)
├── CONTRIBUTING.md          # Contribution guidelines
├── CODE_OF_CONDUCT.md       # Community guidelines
├── LICENSE                  # License file
├── README.md                # Project overview
├── SECURITY.md              # Security policy
├── AUTHORS.md               # Contributors
├── ACKNOWLEDGMENTS.md       # Credits
├── claude.md                # Claude instructions (CREATE LAST)
├── tech-stack.md            # Technology overview (CREATE FIRST, then move to dev/)
├── LEARNINGS.md             # Development insights
├── TODO.md                  # Future enhancements
├── PROJECT_STATUS.md        # Standardization report
└── VERSION_MAP.md           # Version documentation (multi-version only)
```

**VERSION ORGANIZATION RULES**:
1. MAIN/CURRENT version in root
2. Older versions in `versions/` 
3. Numbering starts at v00 (oldest)
4. Each version self-contained
5. Build/run scripts at root
6. Screenshots in `assets/screenshots/`

**NOTE**: After creating CHANGELOG.md and tech-stack.md, move them to the `dev/` folder.

---

## PHASE 3: NAMING CONVENTIONS

**Universal Rules:**
- **Folders**: kebab-case (e.g., `user-auth`, `api-routes`)
- **Config files**: kebab-case with appropriate extension (e.g., `jest.config.js`)
- **Documentation**: UPPERCASE.md for root docs, kebab-case.md for others
- **Environment files**: .env.{environment} (e.g., `.env.local`, `.env.production`)

**Tech-Specific:**
- **JavaScript/TypeScript**: camelCase for files (e.g., `userController.js`)
- **Python**: snake_case for files (e.g., `user_controller.py`)
- **React Components**: PascalCase (e.g., `UserProfile.jsx`)
- **Swift**: PascalCase (e.g., `UserViewController.swift`)

---

## PHASE 4: TECH-SPECIFIC SOURCE ORGANIZATION

### 4.1 IF ELECTRON PROJECT
```
src/
├── main/                # Main process
│   ├── main.js
│   ├── preload.js
│   └── ipc-handlers/
├── renderer/            # Renderer process
│   ├── index.html
│   ├── renderer.js
│   └── components/
└── shared/              # Shared utilities
```
Add to package.json scripts:
- `"start": "electron ."`
- `"dev": "electron . --dev"`
- `"build": "electron-builder"`

### 4.2 IF REACT/NEXT.JS PROJECT
```
src/
├── app/ (or pages/)     # Next.js routes
├── components/
│   ├── common/
│   ├── features/
│   └── layouts/
├── hooks/               # Custom React hooks
├── lib/                 # Utilities, helpers
├── services/            # API services
├── stores/              # State management
├── styles/              # Global styles
└── types/               # TypeScript types
```

### 4.3 IF PYTHON PROJECT
```
src/ (or project_name/)
├── __init__.py
├── api/                 # API endpoints
├── core/                # Core business logic
├── models/              # Data models
├── services/            # Business services
├── utils/               # Utility functions
└── main.py             # Entry point
```
Add files:
- `requirements.txt` or `pyproject.toml`
- `setup.py` if library
- `.python-version`

### 4.4 IF PYTHON GUI PROJECT (Tkinter/CustomTkinter)
```
src/
├── [app_name]/
│   ├── __init__.py
│   ├── main.py                # Application entry point
│   ├── ui/                    # UI components
│   │   ├── __init__.py
│   │   ├── windows/           # Main windows
│   │   ├── widgets/           # Custom widgets
│   │   ├── dialogs/           # Dialog boxes
│   │   └── components/        # Reusable UI components
│   ├── core/                  # Business logic
│   ├── models/                # Data models
│   ├── services/              # External services
│   ├── utils/                 # Utility functions
│   └── resources/             # UI resources (images, fonts)
└── themes/                    # CustomTkinter themes
```

### 4.5 IF NODE.JS PROJECT
```
src/
├── controllers/               # Request handlers
├── models/                    # Data models
├── services/                  # Business logic
├── middleware/                # Express/framework middleware
├── routes/                    # API routes
├── utils/                     # Utility functions
├── config/                    # Application configuration
├── validators/                # Input validation
└── types/                     # TypeScript types (if applicable)
```

### 4.6 IF TYPESCRIPT PROJECT
```
src/
├── types/                     # Type definitions
│   ├── index.ts              # Main type exports
│   ├── api.ts                # API-related types
│   └── common.ts             # Common types
├── interfaces/                # Interface definitions
├── enums/                     # Enumeration definitions
├── controllers/               # Request handlers
├── models/                    # Data models
├── services/                  # Business logic
├── utils/                     # Utility functions
└── config/                    # Configuration files
```

### 4.7 IF SWIFT PROJECT
```
Sources/
├── App/
│   ├── AppDelegate.swift
│   └── SceneDelegate.swift
├── Models/
├── Views/
├── Controllers/
├── Services/
├── Extensions/
└── Resources/
```

### 4.8 IF HTML/CSS/JS PROJECT
```
src/
├── index.html                 # Main HTML file
├── assets/                    # Static assets
│   ├── css/                   # Stylesheets
│   │   ├── main.css
│   │   ├── components/
│   │   └── utilities/
│   ├── js/                    # JavaScript files
│   │   ├── main.js
│   │   ├── components/
│   │   └── modules/
│   ├── images/
│   └── fonts/
├── components/                # HTML component templates
├── layouts/                   # Page layout templates
└── pages/                     # Individual page files
```

### 4.9 IF VITE PROJECT
Add/update `vite.config.ts`:
```typescript
import { defineConfig } from 'vite'
export default defineConfig({
  // Project-specific config
})
```

---

## PHASE 5: INTELLIGENT FILE ORGANIZATION

### 5.1 Manual File Analysis and Organization

**DO NOT USE SCRIPTS - Manually analyze each file and move it intelligently:**

1. **Read each file to understand its purpose**
2. **Determine the best location based on content, not just filename**
3. **Move files one by one with purpose**

### 5.2 File Organization Guidelines

**Source Code Files:**
- Main application entry → `src/` root or `src/main.{ext}`
- UI components → `src/components/` or `src/ui/`
- Business logic → `src/core/` or `src/services/`
- Data models → `src/models/`
- Utilities → `src/utils/` or `src/helpers/`
- API code → `src/api/` or `src/routes/`

**Documentation Files:**
- Product requirements → `dev/PRDs/` (DO NOT CREATE NEW PRDs)
- Technical specs → `dev/specs/`
- User guides → `docs/guides/`
- API docs → `docs/api/`
- Development notes → `dev/notes/`
- Research → `dev/research/`
- Old documentation → `docs/legacy/`
- Changelog → `dev/CHANGELOG.md` (after creation)
- Tech stack → `dev/tech-stack.md` (after creation)

**Asset Files:**
- Application icons → `assets/icons/`
- Screenshots → `assets/screenshots/`
- General images → `assets/images/`
- Fonts → `assets/fonts/`
- Media files → `assets/media/`

**Configuration Files:**
- Build configs → `config/` (copy, don't move root configs)
- Environment configs → root (`.env`, `.env.example`)
- IDE configs → root (`.vscode/`, `.idea/`)
- Linter configs → root (`.eslintrc`, `.prettierrc`)

**Test Files:**
- Unit tests → `tests/unit/`
- Integration tests → `tests/integration/`
- E2E tests → `tests/e2e/`
- Test fixtures → `tests/fixtures/`
- Test utilities → `tests/utils/`

**Build and Distribution:**
- Build outputs → `dist/`
- Temporary builds → `build/`
- Deployment scripts → `scripts/deploy/`
- Build scripts → `scripts/build/`

**Archive and Backup:**
- Old versions → `archive/`
- Deprecated code → `archive/deprecated/`
- Backup files → `backup/`
- `.bak` files → `archive/`

### 5.3 SPECIAL INSTRUCTIONS

**PRESERVE**: Never delete without asking:
- Any custom configuration
- Existing documentation
- .env files (but create .env.example)
- Database files
- User data

**ARCHIVE**: Move to `archive/` folder:
- Old versions
- Deprecated code
- Backup files
- .bak files

**INTELLIGENT DECISIONS**:
- If unsure about file purpose, ask before moving
- Detect monorepo structures and adapt accordingly
- Recognize existing conventions and note conflicts
- If project already well-organized, only add missing pieces

---

## PHASE 6: STANDARD FILES CONTENT

### 6.1 README.md (TEMPLATE)
```markdown
# Project Name

![Status](https://img.shields.io/badge/Status-Active-green)
![Version](https://img.shields.io/badge/Version-1.0.0-blue)
![License](https://img.shields.io/badge/License-MIT-yellow)

## Overview
[Brief description]

## Tech Stack
See [dev/tech-stack.md](dev/tech-stack.md) for details.

## Quick Start
```bash
# Installation
[package manager] install

# Development
./run-source-[platform].[sh/bat]

# Testing
[test command]

# Build
./scripts/compile-build-dist.sh
```

## Project Structure
[Brief explanation of folder structure]

## Documentation
- [API Documentation](docs/api/README.md)
- [Architecture](docs/technical/architecture.md)
- [Setup Guide](docs/guides/setup.md)

## Contributing
See [CONTRIBUTING.md](CONTRIBUTING.md)

## License
[License type]
```

### 6.2 .gitignore (UNIVERSAL BASE)
```
# Dependencies
node_modules/
venv/
.env
*.pyc
__pycache__/

# Build outputs
dist/
build/
out/
*.egg-info/

# IDE
.vscode/
.idea/
*.swp
.DS_Store

# Logs
*.log
logs/

# Testing
coverage/
.coverage
.pytest_cache/

# OS
Thumbs.db

# Archives
backup/
archive/
*.zip
*.tar.gz
```

### 6.3 claude.md (CREATE LAST)
```markdown
# Claude Instructions for [Project Name]

## Project Overview
[Auto-generated summary of project]

## Technology Stack
[Reference to dev/tech-stack.md]

## Key Conventions
- File naming: [Detected convention]
- Code style: [Detected style]
- Testing approach: [Detected approach]

## Important Paths
- Source code: `src/`
- Tests: `tests/`
- Documentation: `docs/`
- Configuration: `config/`
- Build scripts: `scripts/`

## Common Tasks
- To run development: `./run-source-[platform].[sh/bat]`
- To run compiled: `./run-[platform].[sh/bat]`
- To build: `./scripts/compile-build-dist.sh`
- To run tests: `[command]`

## Project-Specific Notes
[Any special considerations discovered]

## Recent Changes
Project standardized on [current date]
- Reorganized folder structure
- Added standard documentation
- Configured development environment
```

### 6.4 LEARNINGS.md (TEMPLATE)
```markdown
# Learning Journey: [Project Name]

## 🎯 What I Set Out to Learn
- Objective 1
- Objective 2

## 💡 Key Discoveries
### Technical Insights
- Discovery about [technology]
- Unexpected behavior in [feature]

### Architecture Decisions
- Why I chose [pattern]
- Trade-offs I considered

## 🚧 Challenges Faced
### Challenge 1: [Name]
**Problem**: Description
**Solution**: How I solved it
**Time Spent**: X hours

## 📚 Resources That Helped
- [Resource 1](link) - Why it was useful
- [Resource 2](link) - Key takeaway

## 🔄 What I'd Do Differently
- Decision 1 and why
- Decision 2 and why

## 🎓 Skills Developed
- [ ] Skill 1
- [ ] Skill 2

## 📈 Next Steps for Learning
Where this knowledge leads next
```

### 6.5 TODO.md (TEMPLATE)
```markdown
# Project Roadmap

## 🔥 High Priority
- [ ] Task 1
- [ ] Task 2

## 📦 Features to Add
- [ ] Feature 1
  - Sub-task 1
  - Sub-task 2
- [ ] Feature 2

## 🐛 Known Issues
- [ ] Bug 1: Description
- [ ] Bug 2: Description

## 💡 Ideas for Enhancement
- Idea 1: Description
- Idea 2: Description

## 🔧 Technical Debt
- [ ] Refactor [component]
- [ ] Add tests for [feature]
- [ ] Optimize [process]

## 📖 Documentation Needs
- [ ] Document API endpoints
- [ ] Add inline code comments
- [ ] Create user guide

## 🚀 Dream Features (v2.0)
Features for when the basics are complete
```

### 6.6 VERSION_MAP.md (TEMPLATE for multi-version)
```markdown
# Version Map - [Project Name]

## Overview
This project has evolved through multiple iterations.

## Version Timeline

### v00_original (Date)
**Purpose**: Initial implementation
**Status**: Archived but functional
**Key Features**:
- Basic functionality

**Run**: `./runProject.sh` → Option 1

### v01_refactor (Date)
**Purpose**: Clean up code
**What Changed**:
- Reorganized structure

**Run**: `./runProject.sh` → Option 2

## Experimental Branches

### CLI_version
**Purpose**: Command-line implementation

## How to Navigate Versions
1. Use `./runProject.sh` for selection
2. Navigate to `versions/vXX_name/`

## Lessons Learned Across Versions
- v00 taught: [lesson]
- v01 taught: [lesson]
```

### 6.7 CHANGELOG.md
```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- New features not yet released

### Changed
- Changes in existing functionality

### Deprecated
- Soon-to-be removed features

### Removed
- Removed features

### Fixed
- Bug fixes

### Security
- Vulnerability fixes

## [1.0.0] - YYYY-MM-DD

### Added
- Initial release
```

**NOTE**: After creating, move to `dev/CHANGELOG.md`

### 6.8 CONTRIBUTING.md
```markdown
# Contributing Guidelines

## How to Contribute

### Reporting Bugs
1. Check if the bug has already been reported
2. Create a detailed bug report with:
   - Clear description
   - Steps to reproduce
   - Expected behavior
   - Actual behavior
   - Screenshots if applicable

### Suggesting Features
1. Check existing feature requests
2. Create a feature request with:
   - Problem it solves
   - Proposed solution
   - Alternative solutions considered

### Submitting Changes
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Code Style
- Follow existing code style
- Add comments for complex logic
- Update documentation
- Add tests for new features

### Testing
- Write unit tests for new features
- Ensure all tests pass
- Maintain or improve code coverage
```

### 6.9 PROJECT_STATUS.md
```markdown
# Project Status Report

**Project**: [Name]
**Standardized**: [Date]
**Score**: X/10

## ✅ Completed
- [x] Archive created
- [x] Folder structure organized
- [x] Files migrated to proper locations
- [x] Naming conventions applied
- [x] Documentation created
- [x] GitHub integration added

## 📊 Analysis
- **Has Source Code**: Yes/No
- **Has Tests**: Yes/No
- **Has Documentation**: Yes/No
- **Has CI/CD**: Yes/No

## 📁 File Organization
- **Source files moved to**: src/
- **Tests moved to**: tests/
- **Documentation in**: docs/
- **Archives in**: archive/

## 🚀 Next Steps
1. Review organized files
2. Update project-specific details in README
3. Add missing tests
4. Configure CI/CD pipeline
```

---

<artifact identifier="unified-project-standardization-final" type="text/markdown" title="Unified Project Standardization Prompt - Final Version">
# 🚀 UNIFIED PROJECT STANDARDIZATION PROMPT - COMPLETE SYNTHESIS

## Quick Usage
Paste this entire document to Claude when in any project folder to standardize it according to best practices.

---

## INSTRUCTION TO CLAUDE

You are about to standardize a project folder structure. Follow these steps EXACTLY and manually organize files based on intelligent analysis of their content and purpose.

---

## 🔴 PHASE 0: PROJECT-LEVEL ARCHIVING - ABSOLUTELY CRITICAL 🔴

# ⚠️ ABSOLUTELY CRITICAL ⚠️
# NEVER SKIP THIS PHASE - NO EXCEPTIONS
# CREATE ARCHIVE BEFORE ANY MODIFICATION
# IF YOU FORGET THIS EVEN ONCE, STOP IMMEDIATELY

### 0.1 Local Archive Protocol
**🚨 CRITICAL REQUIREMENT 🚨**: Before ANY modification to the project, create a local archive  
**🚨 NO EXCEPTIONS 🚨**: Even if the project is empty, broken, or tiny - ARCHIVE IT FIRST  
**🚨 VERIFICATION REQUIRED 🚨**: Must verify archive exists before proceeding

**Archive Structure**:
```
project-root/
├── backup/                      # Backup folder
│   └── original_backup_[timestamp].zip     # Complete zipped archive of original state
└── [working files]              # Files we'll be modifying
```

### 0.2 Archive Creation Process

#### 🛑 STOP AND READ 🛑
**YOU MUST DO THIS BEFORE ANY MODIFICATIONS**  
**DO NOT PROCEED WITHOUT ARCHIVING**  
**THIS IS NOT OPTIONAL**

```bash
# Navigate to the project directory
cd project-root

# 1. Create backup folder
mkdir -p backup

# 2. Create timestamped zip archive of EVERYTHING except the backup folder itself
zip -r "backup/original_backup_$(date +%Y%m%d_%H%M%S).zip" . -x "backup/*" "*.DS_Store"

# Alternative if the project is large or has many files:
tar -czf "backup/original_backup_$(date +%Y%m%d_%H%M%S).tar.gz" --exclude="backup" --exclude=".DS_Store" .

# 3. Verify the backup was created
ls -la backup/

# 4. Verify the backup contains files (quick check)
unzip -l backup/original_backup_*.zip | head -20
# or for tar:
tar -tzf backup/original_backup_*.tar.gz | head -20
```

### 0.3 Archive Verification
Before proceeding with ANY modifications:
1. Verify backup folder exists: `backup/`
2. Verify zip file exists: `backup/original_backup_*.zip`
3. Verify zip is not empty (has actual content)

### 0.4 Archive .gitignore Addition
Add to .gitignore:
```gitignore
# Local backup archives
backup/
*.zip
*.tar.gz
```

### 0.5 Simple Restoration Process
If you need to restore:
```bash
# 1. Navigate to project
cd project-root

# 2. Remove current files (except backup folder)
find . -maxdepth 1 ! -name 'backup' ! -name '.' -exec rm -rf {} \;

# 3. Unzip the backup
unzip backup/original_backup_*.zip

# 4. Remove the backup folder if desired
rm -rf backup/
```

---

## PHASE 1: DISCOVERY & ANALYSIS (Do First)

### 1.1 Initial Discovery Commands
```bash
# 1. Confirm current directory
pwd

# 2. See current structure
ls -la

# 3. Check for tech stack indicators
ls *.json *.txt *.toml *.swift *.xml *.gradle 2>/dev/null

# 4. Look for source files
find . -type f \( -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.jsx" -o -name "*.tsx" -o -name "*.swift" \) | head -20

# 5. Check for existing documentation
find . -name "*.md" -type f | head -20
```

### 1.2 Technology Stack Detection Rules

**Python Projects:**
- Look for: `*.py` files, `requirements.txt`, `setup.py`, `pyproject.toml`, `Pipfile`
- GUI indicators: imports of `tkinter`, `customtkinter`, `PyQt`, `Kivy`
- Framework indicators: `django`, `flask`, `fastapi` in dependencies
- Data Science: `jupyter` notebooks, `pandas`, `numpy`, `matplotlib` imports

**Node.js Projects:**
- Look for: `package.json`, `node_modules/`, `*.js` files with `require()` or ES6 imports
- Framework indicators: `express`, `nest`, `koa`, `hapi` in dependencies
- Build tools: `webpack.config.js`, `vite.config.js`, `rollup.config.js`

**TypeScript Projects:**
- Look for: `tsconfig.json`, `*.ts` files, `@types/` packages in dependencies
- Combined with Node.js or frontend framework indicators

**Electron Projects:**
- Look for: `electron` in dependencies, `main.js` or `electron.js`, preload scripts
- Combined with both Node.js backend and frontend technologies

**React Projects:**
- Look for: `react` in dependencies, `*.jsx` or `*.tsx` files, React imports
- Build tools: Create React App, Next.js, Vite with React

**Swift Projects:**
- Look for: `*.swift` files, `Package.swift`, `*.xcodeproj`, `*.xcworkspace`
- iOS indicators: UIKit, SwiftUI imports, iOS deployment targets
- macOS indicators: AppKit imports, macOS deployment targets

**HTML/CSS/JS Projects:**
- Look for: `index.html`, standalone CSS/JS without package managers
- Modern variants: ES6 modules, CSS preprocessors, build tools

### 1.3 Create Technology Stack Documentation (CREATE FIRST)

Create `/tech-stack.md`:
```markdown
# Technology Stack

## Core Technologies
- **Language**: [Detected language]
- **Framework**: [Detected framework]  
- **Runtime**: [Node.js/Python/etc version]
- **Package Manager**: [npm/yarn/pip/etc]

## Key Dependencies
[List main dependencies found]

## Development Tools
- **Linter**: [ESLint/Pylint/etc]
- **Formatter**: [Prettier/Black/etc]
- **Testing**: [Jest/Pytest/etc]
- **Build Tool**: [Webpack/Vite/etc]

## Project Type
[Web App/Desktop App/CLI Tool/Library/etc]
```

---

## PHASE 2: UNIVERSAL FOLDER STRUCTURE (Apply to ALL Projects)

### 2.1 Standard Directory Structure (Single or Multi-Version)

```
project-root/
├── .github/
│   ├── workflows/
│   │   └── ci.yml
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md
│   │   └── feature_request.md
│   └── PULL_REQUEST_TEMPLATE.md
├── archive/                   # Old versions, deprecated code
├── assets/                    # Images, icons, media files
│   ├── icons/                 # Application icons (ALL ICON FILES HERE)
│   │   ├── icon.png           # Base icon (512x512 or 1024x1024)
│   │   ├── icon.icns          # macOS icon (1024x1024)
│   │   ├── icon.ico           # Windows icon (256x256)
│   │   ├── 16x16.png
│   │   ├── 32x32.png
│   │   ├── 48x48.png
│   │   ├── 64x64.png
│   │   ├── 128x128.png
│   │   ├── 256x256.png
│   │   ├── 512x512.png
│   │   └── entitlements.mac.plist  # macOS entitlements
│   ├── images/
│   └── screenshots/
├── backup/                    # Local archives (from Phase 0)
├── config/                    # Configuration files
├── data/                      # Data files (if applicable)
│   ├── raw/                   # Original data
│   ├── processed/             # Transformed data
│   └── final/                 # Analysis-ready data
├── dev/                       # Development resources
│   ├── PRDs/                  # Product requirement docs (if they exist)
│   ├── specs/                 # Technical specifications
│   ├── notes/                 # Development notes
│   ├── research/              # Research materials
│   └── build-scripts/         # Build script templates for this project
│       ├── build-electron.md  # Electron build instructions
│       ├── build-python.md    # Python build instructions
│       ├── build-swift.md     # Swift build instructions
│       ├── build-typescript.md # TypeScript build instructions
│       └── build-web.md       # Web build instructions
├── dist/                      # Distribution/deployment files (see Phase 7)
├── docs/                      # Documentation
│   ├── api/                   # API documentation
│   ├── guides/                # User guides
│   ├── technical/             # Technical docs
│   │   ├── architecture.md
│   │   └── deployment/
│   ├── development/           # Developer guides
│   ├── internal/              # Internal docs
│   └── legacy/                # Archived docs
├── examples/                  # Usage examples
├── scripts/                   # Build and utility scripts
│   ├── compile-build-dist.sh # Main build script
│   ├── build/                 # Build-related scripts
│   ├── deploy/                # Deployment scripts
│   └── utils/                 # Utility scripts
├── src/                       # Source code (varies by stack)
├── tests/                     # Test files
│   ├── unit/
│   ├── integration/
│   └── e2e/
├── tools/                     # Development tools
├── versions/                  # ONLY for multi-version projects
│   ├── v00/                   # Oldest version
│   │   ├── README.md
│   │   ├── CHANGES.md
│   │   └── [v00 code]
│   └── v01/                   # Next version
├── shared/                    # Shared resources (multi-version only)
│
├── run-source-macos.sh        # Run from source on macOS
├── run-source-windows.bat     # Run from source on Windows
├── run-source-linux.sh        # Run from source on Linux
├── run-macos.sh              # Run compiled macOS binary
├── run-windows.bat           # Run compiled Windows binary
├── run-linux.sh              # Run compiled Linux binary
├── runProject.sh             # Version selector (multi-version only)
├── setup.sh                  # Setup script
│
├── .env.example              # Environment variables template
├── .gitignore               # Git ignore rules
├── .gitattributes           # Git file attributes
├── CHANGELOG.md             # Version history (move to dev/ after creation)
├── CONTRIBUTING.md          # Contribution guidelines
├── CODE_OF_CONDUCT.md       # Community guidelines
├── LICENSE                  # License file
├── README.md                # Project overview
├── SECURITY.md              # Security policy
├── AUTHORS.md               # Contributors
├── ACKNOWLEDGMENTS.md       # Credits
├── claude.md                # Claude instructions (CREATE LAST)
├── tech-stack.md            # Technology overview (CREATE FIRST, then move to dev/)
├── LEARNINGS.md             # Development insights
├── TODO.md                  # Future enhancements
├── PROJECT_STATUS.md        # Standardization report
└── VERSION_MAP.md           # Version documentation (multi-version only)
```

**VERSION ORGANIZATION RULES**:
1. MAIN/CURRENT version in root
2. Older versions in `versions/` 
3. Numbering starts at v00 (oldest)
4. Each version self-contained
5. Build/run scripts at root
6. Screenshots in `assets/screenshots/`

**NOTE**: After creating CHANGELOG.md and tech-stack.md, move them to the `dev/` folder.

---

## PHASE 3: NAMING CONVENTIONS

**Universal Rules:**
- **Folders**: kebab-case (e.g., `user-auth`, `api-routes`)
- **Config files**: kebab-case with appropriate extension (e.g., `jest.config.js`)
- **Documentation**: UPPERCASE.md for root docs, kebab-case.md for others
- **Environment files**: .env.{environment} (e.g., `.env.local`, `.env.production`)

**Tech-Specific:**
- **JavaScript/TypeScript**: camelCase for files (e.g., `userController.js`)
- **Python**: snake_case for files (e.g., `user_controller.py`)
- **React Components**: PascalCase (e.g., `UserProfile.jsx`)
- **Swift**: PascalCase (e.g., `UserViewController.swift`)

---

## PHASE 4: TECH-SPECIFIC SOURCE ORGANIZATION

### 4.1 IF ELECTRON PROJECT
```
src/
├── main/                # Main process
│   ├── main.js
│   ├── preload.js
│   └── ipc-handlers/
├── renderer/            # Renderer process
│   ├── index.html
│   ├── renderer.js
│   └── components/
└── shared/              # Shared utilities
```
Add to package.json scripts:
- `"start": "electron ."`
- `"dev": "electron . --dev"`
- `"build": "electron-builder"`

### 4.2 IF REACT/NEXT.JS PROJECT
```
src/
├── app/ (or pages/)     # Next.js routes
├── components/
│   ├── common/
│   ├── features/
│   └── layouts/
├── hooks/               # Custom React hooks
├── lib/                 # Utilities, helpers
├── services/            # API services
├── stores/              # State management
├── styles/              # Global styles
└── types/               # TypeScript types
```

### 4.3 IF PYTHON PROJECT
```
src/ (or project_name/)
├── __init__.py
├── api/                 # API endpoints
├── core/                # Core business logic
├── models/              # Data models
├── services/            # Business services
├── utils/               # Utility functions
└── main.py             # Entry point
```
Add files:
- `requirements.txt` or `pyproject.toml`
- `setup.py` if library
- `.python-version`

### 4.4 IF PYTHON GUI PROJECT (Tkinter/CustomTkinter)
```
src/
├── [app_name]/
│   ├── __init__.py
│   ├── main.py                # Application entry point
│   ├── ui/                    # UI components
│   │   ├── __init__.py
│   │   ├── windows/           # Main windows
│   │   ├── widgets/           # Custom widgets
│   │   ├── dialogs/           # Dialog boxes
│   │   └── components/        # Reusable UI components
│   ├── core/                  # Business logic
│   ├── models/                # Data models
│   ├── services/              # External services
│   ├── utils/                 # Utility functions
│   └── resources/             # UI resources (images, fonts)
└── themes/                    # CustomTkinter themes
```

### 4.5 IF NODE.JS PROJECT
```
src/
├── controllers/               # Request handlers
├── models/                    # Data models
├── services/                  # Business logic
├── middleware/                # Express/framework middleware
├── routes/                    # API routes
├── utils/                     # Utility functions
├── config/                    # Application configuration
├── validators/                # Input validation
└── types/                     # TypeScript types (if applicable)
```

### 4.6 IF TYPESCRIPT PROJECT
```
src/
├── types/                     # Type definitions
│   ├── index.ts              # Main type exports
│   ├── api.ts                # API-related types
│   └── common.ts             # Common types
├── interfaces/                # Interface definitions
├── enums/                     # Enumeration definitions
├── controllers/               # Request handlers
├── models/                    # Data models
├── services/                  # Business logic
├── utils/                     # Utility functions
└── config/                    # Configuration files
```

### 4.7 IF SWIFT PROJECT
```
Sources/
├── App/
│   ├── AppDelegate.swift
│   └── SceneDelegate.swift
├── Models/
├── Views/
├── Controllers/
├── Services/
├── Extensions/
└── Resources/
```

### 4.8 IF HTML/CSS/JS PROJECT
```
src/
├── index.html                 # Main HTML file
├── assets/                    # Static assets
│   ├── css/                   # Stylesheets
│   │   ├── main.css
│   │   ├── components/
│   │   └── utilities/
│   ├── js/                    # JavaScript files
│   │   ├── main.js
│   │   ├── components/
│   │   └── modules/
│   ├── images/
│   └── fonts/
├── components/                # HTML component templates
├── layouts/                   # Page layout templates
└── pages/                     # Individual page files
```

### 4.9 IF VITE PROJECT
Add/update `vite.config.ts`:
```typescript
import { defineConfig } from 'vite'
export default defineConfig({
  // Project-specific config
})
```

---

## PHASE 5: INTELLIGENT FILE ORGANIZATION

### 5.1 Manual File Analysis and Organization

**DO NOT USE SCRIPTS - Manually analyze each file and move it intelligently:**

1. **Read each file to understand its purpose**
2. **Determine the best location based on content, not just filename**
3. **Move files one by one with purpose**

### 5.2 File Organization Guidelines

**Source Code Files:**
- Main application entry → `src/` root or `src/main.{ext}`
- UI components → `src/components/` or `src/ui/`
- Business logic → `src/core/` or `src/services/`
- Data models → `src/models/`
- Utilities → `src/utils/` or `src/helpers/`
- API code → `src/api/` or `src/routes/`

**Documentation Files:**
- Product requirements → `dev/PRDs/` (DO NOT CREATE NEW PRDs)
- Technical specs → `dev/specs/`
- User guides → `docs/guides/`
- API docs → `docs/api/`
- Development notes → `dev/notes/`
- Research → `dev/research/`
- Old documentation → `docs/legacy/`
- Changelog → `dev/CHANGELOG.md` (after creation)
- Tech stack → `dev/tech-stack.md` (after creation)

**Asset Files:**
- Application icons → `assets/icons/`
- Screenshots → `assets/screenshots/`
- General images → `assets/images/`
- Fonts → `assets/fonts/`
- Media files → `assets/media/`

**Configuration Files:**
- Build configs → `config/` (copy, don't move root configs)
- Environment configs → root (`.env`, `.env.example`)
- IDE configs → root (`.vscode/`, `.idea/`)
- Linter configs → root (`.eslintrc`, `.prettierrc`)

**Test Files:**
- Unit tests → `tests/unit/`
- Integration tests → `tests/integration/`
- E2E tests → `tests/e2e/`
- Test fixtures → `tests/fixtures/`
- Test utilities → `tests/utils/`

**Build and Distribution:**
- Build outputs → `dist/`
- Temporary builds → `build/`
- Deployment scripts → `scripts/deploy/`
- Build scripts → `scripts/build/`

**Archive and Backup:**
- Old versions → `archive/`
- Deprecated code → `archive/deprecated/`
- Backup files → `backup/`
- `.bak` files → `archive/`

### 5.3 SPECIAL INSTRUCTIONS

**PRESERVE**: Never delete without asking:
- Any custom configuration
- Existing documentation
- .env files (but create .env.example)
- Database files
- User data

**ARCHIVE**: Move to `archive/` folder:
- Old versions
- Deprecated code
- Backup files
- .bak files

**INTELLIGENT DECISIONS**:
- If unsure about file purpose, ask before moving
- Detect monorepo structures and adapt accordingly
- Recognize existing conventions and note conflicts
- If project already well-organized, only add missing pieces

---

## PHASE 6: STANDARD FILES CONTENT

### 6.1 README.md (TEMPLATE)
```markdown
# Project Name

![Status](https://img.shields.io/badge/Status-Active-green)
![Version](https://img.shields.io/badge/Version-1.0.0-blue)
![License](https://img.shields.io/badge/License-MIT-yellow)

## Overview
[Brief description]

## Tech Stack
See [dev/tech-stack.md](dev/tech-stack.md) for details.

## Quick Start
```bash
# Installation
[package manager] install

# Development
./run-source-[platform].[sh/bat]

# Testing
[test command]

# Build
./scripts/compile-build-dist.sh
```

## Project Structure
[Brief explanation of folder structure]

## Documentation
- [API Documentation](docs/api/README.md)
- [Architecture](docs/technical/architecture.md)
- [Setup Guide](docs/guides/setup.md)

## Contributing
See [CONTRIBUTING.md](CONTRIBUTING.md)

## License
[License type]
```

### 6.2 .gitignore (UNIVERSAL BASE)
```
# Dependencies
node_modules/
venv/
.env
*.pyc
__pycache__/

# Build outputs
dist/
build/
out/
*.egg-info/

# IDE
.vscode/
.idea/
*.swp
.DS_Store

# Logs
*.log
logs/

# Testing
coverage/
.coverage
.pytest_cache/

# OS
Thumbs.db

# Archives
backup/
archive/
*.zip
*.tar.gz
```

### 6.3 claude.md (CREATE LAST)
```markdown
# Claude Instructions for [Project Name]

## Project Overview
[Auto-generated summary of project]

## Technology Stack
[Reference to dev/tech-stack.md]

## Key Conventions
- File naming: [Detected convention]
- Code style: [Detected style]
- Testing approach: [Detected approach]

## Important Paths
- Source code: `src/`
- Tests: `tests/`
- Documentation: `docs/`
- Configuration: `config/`
- Build scripts: `scripts/`
- Build templates: `dev/build-scripts/`

## Common Tasks
- To run development: `./run-source-[platform].[sh/bat]`
- To run compiled: `./run-[platform].[sh/bat]`
- To build: `./scripts/compile-build-dist.sh`
- To run tests: `[command]`

## Project-Specific Notes
[Any special considerations discovered]

## Recent Changes
Project standardized on [current date]
- Reorganized folder structure
- Added standard documentation
- Configured development environment
```

### 6.4 LEARNINGS.md (TEMPLATE)
```markdown
# Learning Journey: [Project Name]

## 🎯 What I Set Out to Learn
- Objective 1
- Objective 2

## 💡 Key Discoveries
### Technical Insights
- Discovery about [technology]
- Unexpected behavior in [feature]

### Architecture Decisions
- Why I chose [pattern]
- Trade-offs I considered

## 🚧 Challenges Faced
### Challenge 1: [Name]
**Problem**: Description
**Solution**: How I solved it
**Time Spent**: X hours

## 📚 Resources That Helped
- [Resource 1](link) - Why it was useful
- [Resource 2](link) - Key takeaway

## 🔄 What I'd Do Differently
- Decision 1 and why
- Decision 2 and why

## 🎓 Skills Developed
- [ ] Skill 1
- [ ] Skill 2

## 📈 Next Steps for Learning
Where this knowledge leads next
```

### 6.5 TODO.md (TEMPLATE)
```markdown
# Project Roadmap

## 🔥 High Priority
- [ ] Task 1
- [ ] Task 2

## 📦 Features to Add
- [ ] Feature 1
  - Sub-task 1
  - Sub-task 2
- [ ] Feature 2

## 🐛 Known Issues
- [ ] Bug 1: Description
- [ ] Bug 2: Description

## 💡 Ideas for Enhancement
- Idea 1: Description
- Idea 2: Description

## 🔧 Technical Debt
- [ ] Refactor [component]
- [ ] Add tests for [feature]
- [ ] Optimize [process]

## 📖 Documentation Needs
- [ ] Document API endpoints
- [ ] Add inline code comments
- [ ] Create user guide

## 🚀 Dream Features (v2.0)
Features for when the basics are complete
```

### 6.6 VERSION_MAP.md (TEMPLATE for multi-version)
```markdown
# Version Map - [Project Name]

## Overview
This project has evolved through multiple iterations.

## Version Timeline

### v00_original (Date)
**Purpose**: Initial implementation
**Status**: Archived but functional
**Key Features**:
- Basic functionality

**Run**: `./runProject.sh` → Option 1

### v01_refactor (Date)
**Purpose**: Clean up code
**What Changed**:
- Reorganized structure

**Run**: `./runProject.sh` → Option 2

## Experimental Branches

### CLI_version
**Purpose**: Command-line implementation

## How to Navigate Versions
1. Use `./runProject.sh` for selection
2. Navigate to `versions/vXX_name/`

## Lessons Learned Across Versions
- v00 taught: [lesson]
- v01 taught: [lesson]
```

### 6.7 CHANGELOG.md
```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- New features not yet released

### Changed
- Changes in existing functionality

### Deprecated
- Soon-to-be removed features

### Removed
- Removed features

### Fixed
- Bug fixes

### Security
- Vulnerability fixes

## [1.0.0] - YYYY-MM-DD

### Added
- Initial release
```

**NOTE**: After creating, move to `dev/CHANGELOG.md`

### 6.8 CONTRIBUTING.md
```markdown
# Contributing Guidelines

## How to Contribute

### Reporting Bugs
1. Check if the bug has already been reported
2. Create a detailed bug report with:
   - Clear description
   - Steps to reproduce
   - Expected behavior
   - Actual behavior
   - Screenshots if applicable

### Suggesting Features
1. Check existing feature requests
2. Create a feature request with:
   - Problem it solves
   - Proposed solution
   - Alternative solutions considered

### Submitting Changes
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Code Style
- Follow existing code style
- Add comments for complex logic
- Update documentation
- Add tests for new features

### Testing
- Write unit tests for new features
- Ensure all tests pass
- Maintain or improve code coverage
```

### 6.9 PROJECT_STATUS.md
```markdown
# Project Status Report

**Project**: [Name]
**Standardized**: [Date]
**Score**: X/10

## ✅ Completed
- [x] Archive created
- [x] Folder structure organized
- [x] Files migrated to proper locations
- [x] Naming conventions applied
- [x] Documentation created
- [x] GitHub integration added

## 📊 Analysis
- **Has Source Code**: Yes/No
- **Has Tests**: Yes/No
- **Has Documentation**: Yes/No
- **Has CI/CD**: Yes/No

## 📁 File Organization
- **Source files moved to**: src/
- **Tests moved to**: tests/
- **Documentation in**: docs/
- **Archives in**: archive/

## 🚀 Next Steps
1. Review organized files
2. Update project-specific details in README
3. Add missing tests
4. Configure CI/CD pipeline
```

---

## PHASE 7: BUILD SYSTEM IMPLEMENTATION

### 7.1 Build System Architecture

**Build Script Location**: `/scripts/compile-build-dist.sh`
**Build Templates Location**: `/dev/swarm/`

**CRITICAL BUILD REQUIREMENTS**:
- **ALWAYS purge the contents of `/dist` folder before building**: `rm -rf dist/*`
- **Look for and use icon from within `/assets/icons/` folder**
- **Copy icon.png to icon.ico and resize to 256x256**
- **If an icon does not exist, create one based on the app description**
- **Set parallel build optimization for Electron**: `export ELECTRON_BUILDER_PARALLELISM=18`
- **Clean system temp directories before and after build**
- **Use custom temp directory for builds to avoid system pollution**

### 7.2 Build Script Templates

Based on the detected technology stack, copy the appropriate build template from `/dev/swarm/` to `/scripts/compile-build-dist.sh`:

**Build Templates Location in Each Project:**
```
dev/swarm/
├── build-compile-dist-electron.md     # Electron + Node/TypeScript builds
├── build-compile-dist-python.md       # Python (GUI/CLI) builds
├── build-compile-dist-swift-macos.md  # Swift/macOS builds
├── build-compile-dist-typescript.md   # TypeScript/Node builds
└── build-compile-dist-web.md          # HTML/CSS/JS optimization
```

**Build Template Selection:**

| File | Technology | Description |
|------|------------|-------------|
| `build-compile-dist-electron.md` | Electron + Node/TypeScript | Multi-platform desktop app builds |
| `build-compile-dist-python.md` | Python (GUI/CLI) | PyInstaller compilation |
| `build-compile-dist-swift-macos.md` | Swift/macOS | Xcode automation |
| `build-compile-dist-typescript.md` | TypeScript/Node | TypeScript compilation |
| `build-compile-dist-web.md` | HTML/CSS/JS | Web optimization |

**Note**: These build scripts are self-contained within each project's `/dev/swarm/` folder. Copy the appropriate script content to `/scripts/compile-build-dist.sh` based on your project's technology stack.
```

### 7.3 System Temp Cleanup Functions

**Add these cleanup functions to all build scripts:**

```bash
# Function to cleanup system temp directories
cleanup_system_temp() {
    echo "Cleaning system temp directories..."
    
    # macOS temp cleanup
    if [ "$(uname)" = "Darwin" ]; then
        TEMP_DIR=$(find /private/var/folders -name "Temporary*" -type d 2>/dev/null | head -1)
        if [ -n "$TEMP_DIR" ]; then
            PARENT_DIR=$(dirname "$TEMP_DIR")
            # Clean up build artifacts (older than 1 day)
            find "$PARENT_DIR" -name "t-*" -type d -mtime +1 -exec rm -rf {} + 2>/dev/null || true
            find "$PARENT_DIR" -name "electron-download-*" -type d -mtime +1 -exec rm -rf {} + 2>/dev/null || true
            find "$PARENT_DIR" -name "pyinstaller-*" -type d -mtime +1 -exec rm -rf {} + 2>/dev/null || true
            find "$PARENT_DIR" -name "npm-*" -type d -mtime +1 -exec rm -rf {} + 2>/dev/null || true
        fi
    fi
    
    # Linux temp cleanup
    if [ "$(uname)" = "Linux" ]; then
        if [ -d "/tmp" ]; then
            find /tmp -name "electron-*" -type d -mtime +1 -exec rm -rf {} + 2>/dev/null || true
            find /tmp -name "npm-*" -type d -mtime +1 -exec rm -rf {} + 2>/dev/null || true
            find /tmp -name "pyinstaller-*" -type d -mtime +1 -exec rm -rf {} + 2>/dev/null || true
        fi
    fi
    
    # Project-specific cleanup
    rm -rf node_modules/.cache 2>/dev/null || true
    rm -rf .build 2>/dev/null || true
    rm -rf build-temp 2>/dev/null || true
    rm -rf __pycache__ 2>/dev/null || true
    find . -name "*.pyc" -delete 2>/dev/null || true
    find . -name ".DS_Store" -delete 2>/dev/null || true
}

# Function to setup build temp directory
setup_build_temp() {
    BUILD_TEMP_DIR="$(pwd)/build-temp"
    mkdir -p "$BUILD_TEMP_DIR"
    export TMPDIR="$BUILD_TEMP_DIR"
    export TMP="$BUILD_TEMP_DIR"
    export TEMP="$BUILD_TEMP_DIR"
    export ELECTRON_CACHE="$BUILD_TEMP_DIR/electron-cache"
    export PYINSTALLER_WORKDIR="$BUILD_TEMP_DIR/pyinstaller"
    echo "Using custom temp directory: $BUILD_TEMP_DIR"
}

# Function to cleanup build temp
cleanup_build_temp() {
    if [ -n "$BUILD_TEMP_DIR" ] && [ -d "$BUILD_TEMP_DIR" ]; then
        echo "Cleaning build temp directory..."
        rm -rf "$BUILD_TEMP_DIR" 2>/dev/null || true
    fi
}
```

### 7.4 Universal Build Requirements

1. **Build script MUST be in**: `scripts/compile-build-dist.sh`
2. **ALWAYS purge `/dist` before building**: `rm -rf dist/*`
3. **After macOS compilation**: Create symlink in project root to .app bundle
4. **Output structure**: All builds go to `/dist` folder
5. **Icon handling**: 
   - Use icons from `assets/icons/` folder
   - Convert icon.png to icon.ico (256x256) for Windows
   - Create icon.icns (1024x1024) for macOS
   - If icon doesn't exist, create based on app description
6. **Optimization settings**:
   - Electron parallel builds: `export ELECTRON_BUILDER_PARALLELISM=18`
   - Use custom temp directory to avoid system pollution
   - Clean system temps before and after build
7. **Run scripts in project root**:
   - `run-source-macos.sh` - Run from source on macOS
   - `run-source-windows.bat` - Run from source on Windows
   - `run-source-linux.sh` - Run from source on Linux
   - `run-macos.sh` - Run compiled macOS binary
   - `run-windows.bat` - Run compiled Windows binary
   - `run-linux.sh` - Run compiled Linux binary

### 7.5 Required /dist Folder Structure

**BEFORE BUILDING**: Always execute:
```bash
rm -rf dist/*
cleanup_system_temp
setup_build_temp
```

After running `compile-build-dist.sh`, the `/dist` folder should contain:
```
dist/
├── linux-unpacked/          # Unpacked Linux application files
├── mac/                     # macOS Intel build
│   └── [AppName].app        # Intel .app bundle
├── mac-arm64/              # macOS ARM64 build
│   └── [AppName].app        # ARM64 .app bundle
├── win-unpacked/           # Unpacked Windows application files
├── win-ia32-unpacked/      # Unpacked Windows 32-bit files
├── builder-debug.yml       # Electron-builder debug info
├── latest-linux.yml        # Linux update info
├── latest-mac.yml          # macOS update info
├── latest.yml              # General update info
├── [AppName] Setup [version].exe              # Windows NSIS installer
├── [AppName] Setup [version].exe.blockmap     # Windows blockmap
├── [AppName] Setup [version].msi              # Windows MSI installer
├── [AppName]-[version]-arm64.dmg              # macOS ARM64 DMG
├── [AppName]-[version]-arm64.dmg.blockmap     # macOS ARM64 blockmap
├── [AppName]-[version]-win.zip                # Windows portable
├── [AppName]-[version]-ia32-win.zip           # Windows 32-bit portable
├── [AppName]-[version].AppImage               # Linux AppImage
├── [AppName]-[version].deb                    # Debian/Ubuntu package
├── [AppName]-[version].rpm                    # RedHat/Fedora package
├── [AppName]-[version].snap                   # Snap package
├── [AppName]-[version].dmg                    # macOS Intel DMG
├── [AppName]-[version].dmg.blockmap           # macOS Intel blockmap
└── [AppName]-[version].zip                    # macOS portable
```

### 7.6 Platform-Specific Run Scripts (CREATE ALL OF THESE)

**run-source-macos.sh (Project Root):**
```bash
#!/bin/bash
# Run from Source on macOS (Development Mode)

cd "$(dirname "$0")"

# Check platform
if [ "$(uname)" != "Darwin" ]; then
    echo "This script is for macOS only"
    exit 1
fi

# Install dependencies if needed
if [ ! -d "node_modules" ] && [ -f "package.json" ]; then
    npm install
fi

# Run based on project type
if [ -f "package.json" ]; then
    npm start
elif [ -f "requirements.txt" ]; then
    python3 src/main.py
elif [ -f "Package.swift" ]; then
    swift run
else
    echo "Unknown project type"
    exit 1
fi
run-source-linux.sh (Project Root):
bash#!/bin/bash
# Run from Source on Linux (Development Mode)

cd "$(dirname "$0")"

# Check platform
if [ "$(uname)" != "Linux" ]; then
    echo "This script is for Linux only"
    exit 1
fi

# Install dependencies if needed
if [ ! -d "node_modules" ] && [ -f "package.json" ]; then
    npm install
fi

# Run based on project type
if [ -f "package.json" ]; then
    npm start
elif [ -f "requirements.txt" ]; then
    python3 src/main.py
else
    echo "Unknown project type"
    exit 1
fi
run-source-windows.bat (Project Root):
batch@echo off
REM Run from Source on Windows (Development Mode)

cd /d "%~dp0"

REM Check for Node.js project
if exist "package.json" (
    if not exist "node_modules" (
        npm install
    )
    npm start
    exit /b
)

REM Check for Python project
if exist "requirements.txt" (
    python src\main.py
    exit /b
)

echo Unknown project type
exit /b 1
run-macos.sh (Project Root):
bash#!/bin/bash
# Run Compiled Binary on macOS

cd "$(dirname "$0")"

# Check platform
if [ "$(uname)" != "Darwin" ]; then
    echo "This script is for macOS only"
    exit 1
fi

# Check for symlink to .app
if [ -L "Application.app" ]; then
    open "Application.app"
elif [ -d "dist/mac/Application.app" ]; then
    open "dist/mac/Application.app"
elif [ -d "dist/mac-arm64/Application.app" ]; then
    open "dist/mac-arm64/Application.app"
else
    echo "No compiled application found. Run: ./scripts/compile-build-dist.sh"
    exit 1
fi
run-linux.sh (Project Root):
bash#!/bin/bash
# Run Compiled Binary on Linux

cd "$(dirname "$0")"

# Check platform
if [ "$(uname)" != "Linux" ]; then
    echo "This script is for Linux only"
    exit 1
fi

# Check for AppImage
if ls dist/*.AppImage 1> /dev/null 2>&1; then
    APPIMAGE=$(ls dist/*.AppImage | head -1)
    chmod +x "$APPIMAGE"
    "$APPIMAGE"
# Check for unpacked version
elif [ -d "dist/linux-unpacked" ]; then
    EXECUTABLE=$(find dist/linux-unpacked -maxdepth 1 -type f -executable | head -1)
    if [ -n "$EXECUTABLE" ]; then
        "$EXECUTABLE"
    else
        echo "No executable found in dist/linux-unpacked"
        exit 1
    fi
else
    echo "No compiled application found. Run: ./scripts/compile-build-dist.sh"
    exit 1
fi
run-windows.bat (Project Root):
batch@echo off
REM Run Compiled Binary on Windows

cd /d "%~dp0"

REM Check for installer
if exist "dist\*.exe" (
    for %%f in (dist\*.exe) do (
        start "" "%%f"
        exit /b
    )
)

REM Check for unpacked version
if exist "dist\win-unpacked" (
    for %%f in (dist\win-unpacked\*.exe) do (
        start "" "%%f"
        exit /b
    )
)

echo No compiled application found. Run: scripts\compile-build-dist.sh
exit /b 1
setup.sh (Project Root - Optional but recommended):
bash#!/bin/bash
# Project Setup Script

echo "🚀 Setting up project..."

# Create required directories
mkdir -p src tests docs config scripts assets/icons assets/images assets/screenshots
mkdir -p dev/swarm dev/PRDs dev/specs dev/notes dev/research
mkdir -p archive backup dist

# Make all shell scripts executable
chmod +x run-*.sh 2>/dev/null
chmod +x scripts/*.sh 2>/dev/null

# Install dependencies based on project type
if [ -f "package.json" ]; then
    echo "📦 Installing Node.js dependencies..."
    npm install
elif [ -f "requirements.txt" ]; then
    echo "🐍 Setting up Python virtual environment..."
    python3 -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt
fi

echo "✅ Setup complete!"
echo ""
echo "Available commands:"
echo "  Development:"
echo "    ./run-source-macos.sh    - Run from source (macOS)"
echo "    ./run-source-linux.sh    - Run from source (Linux)"
echo "    ./run-source-windows.bat - Run from source (Windows)"
echo ""
echo "  Production:"
echo "    ./scripts/compile-build-dist.sh - Build application"
echo "    ./run-macos.sh           - Run compiled app (macOS)"
echo "    ./run-windows.bat        - Run compiled app (Windows)"
echo "    ./run-linux.sh           - Run compiled app (Linux)"

### 7.7 Set Executable Permissions

After creating all shell scripts:
bashchmod +x scripts/compile-build-dist.sh
chmod +x run-source-macos.sh
chmod +x run-source-linux.sh
chmod +x run-macos.sh
chmod +x run-linux.sh
chmod +x setup.sh

### 7.8 Build System Features

This complete build system provides:
- ✅ All platform support (macOS Intel/ARM, Windows x64/x86, Linux x64)
- ✅ All installer types (.dmg, .exe, .msi, .deb, .rpm, .AppImage, .snap)
- ✅ Development and production run scripts for all platforms
- ✅ Comprehensive error handling and status reporting
- ✅ Auto-update support files
- ✅ Professional build output with color-coded messages
- ✅ System temp cleanup to prevent disk bloat
- ✅ Custom temp directories for clean builds
- ✅ Parallel compilation optimization (18 cores)
- ✅ Automatic icon generation and conversion
- ✅ Self-contained build scripts within each project

**Additional Notes**:
- **Windows MSI**: Requires WiX Toolset installed on Windows for MSI generation
- **Linux Snap**: Requires snapcraft installed for snap package creation
- **Code Signing**: Add certificates for production releases
- **Auto-Update**: Configure GitHub releases or other update servers
- **CI/CD**: These scripts work with GitHub Actions, CircleCI, Travis CI, etc.
- **Temp Management**: Always uses local build-temp directory to avoid system pollution
- **Icon Requirements**: Place base icon.png in assets/icons/ for automatic conversion
- **Build Templates**: All build scripts stored locally in dev/build-scripts/ for self-contained projects

### 7.9 EXECUTE THE BUILD

**CRITICAL: ACTUALLY BUILD THE PROJECT**

After setting up all build scripts and permissions:
```bash
# ACTUALLY RUN THE BUILD
echo "🚀 BUILDING THE PROJECT..."
./scripts/compile-build-dist.sh

# Verify build succeeded
if [ -d "dist" ] && [ "$(ls -A dist)" ]; then
    echo "✅ BUILD SUCCESSFUL - Files in dist/"
    ls -la dist/
else
    echo "❌ BUILD FAILED - Check errors above"
    exit 1
fi

# Create macOS symlink if .app was built
if [ -d "dist/mac/"*.app ] || [ -d "dist/mac-arm64/"*.app ]; then
    APP_PATH=$(find dist -name "*.app" -type d | head -1)
    if [ -n "$APP_PATH" ]; then
        APP_NAME=$(basename "$APP_PATH")
        ln -sf "$APP_PATH" "$APP_NAME"
        echo "Created symlink: $APP_NAME -> $APP_PATH"
    fi
fi
BUILD IS MANDATORY - DO NOT SKIP THIS STEP

## AND UPDATE THE EXECUTION CHECKLIST Phase 12:

Add under "Build System" section:
```markdown
### Build System
- [ ] Copied appropriate build templates to dev/swarm/
- [ ] Created scripts/compile-build-dist.sh from template
- [ ] Created all run-source-*.sh/bat scripts in root
- [ ] Created all run-*.sh/bat scripts in root
- [ ] Set executable permissions on all shell scripts
- [ ] **EXECUTED THE BUILD SCRIPT** ← ADD THIS
- [ ] Verified dist/ folder has build outputs ← ADD THIS
- [ ] Created macOS symlink if applicable ← ADD THIS

---

## PHASE 8: DOCUMENTATION ORGANIZATION & ANALYSIS

### 8.1 File Content Analysis Protocol

**MANDATORY: Read and analyze EVERY file before organizing**

For each documentation file found:
1. **Read the full content** to understand purpose and audience
2. **Identify the primary audience**: User/Developer/Contributor/Technical
3. **Determine the content type**: Guide/Specification/Reference/Historical
4. **Assess current organization**: Is it in the right place?
5. **Check for duplicates**: Does similar content exist elsewhere?
6. **Evaluate quality**: Is the content current and accurate?

### 8.2 Documentation Structure

```
docs/
├── README.md                    # Main documentation index
├── api/                        # API documentation
│   └── README.md              # API reference index
├── guides/                     # User guides
│   ├── setup.md               # Installation guide
│   └── usage.md               # Usage guide
├── technical/                  # Technical documentation
│   ├── architecture.md        # System architecture
│   ├── tech-stack.md          # Technology details
│   └── deployment/            # Deployment guides
├── development/                # Developer guides
│   └── workflow.md            # Development workflow
├── internal/                   # Internal documentation
│   ├── learnings.md           # Development insights
│   ├── todo.md                # Task tracking
│   └── version-map.md         # Version planning
└── legacy/                     # Archived documentation
    ├── README.md              # Legacy content index
    └── [dated-folders]/       # YYYY-MM-DD archives
```

### 8.3 File Placement Matrix

| Content Type | Primary Audience | Best Location | Example Files |
|-------------|------------------|---------------|---------------|
| Product Requirements | All | `dev/PRDs/` | Existing PRD files only |
| Technical Architecture | Developers | `docs/technical/` | `architecture.md` |
| API Documentation | Developers | `docs/api/` | `api.md`, `endpoints.md` |
| Setup Instructions | Users | `docs/guides/setup.md` | `setup.md`, `installation.md` |
| Development Workflow | Contributors | `docs/development/` | `workflow.md` |
| Legacy Code | Historical | `docs/legacy/` | Old implementations |

### 8.4 Documentation Quality Standards

**MANDATORY: Apply these standards to ALL documentation**

#### File Naming Convention
- Use `kebab-case` for multi-word filenames: `streaming-guide.md`
- Use `PascalCase` only for component-specific docs: `VideoPlayer.md`
- Include version numbers when relevant: `api-v2.md`
- Avoid special characters except hyphens and underscores

#### Content Structure Standards
- **Headers**: Use consistent hierarchy (H1 → H2 → H3)
- **Code Blocks**: Include language identifiers
- **Links**: Use relative paths for internal references
- **Tables**: Use markdown tables for structured data
- **Lists**: Use consistent bullet/dash patterns

#### Documentation Metadata
Every documentation file MUST include:
```markdown
---
title: Document Title
description: Brief description of content
audience: users | developers | contributors | technical
last-updated: YYYY-MM-DD
version: 1.0.0
related-docs: [list of related documents]
---
```

### 8.5 Cross-Reference Implementation

**MANDATORY: Implement comprehensive cross-referencing**

#### Internal Linking Strategy
```markdown
<!-- Link to related documents -->
See also: [Setup Guide](../guides/setup.md)
Related: [API Reference](../technical/api/README.md)
Technical Details: [Architecture](../technical/architecture.md)
```

#### Navigation Breadcrumbs
```markdown
📖 **Documentation** → **Technical** → **API Reference**
```

#### Related Documents Section
Every document should end with:
```markdown
## 📚 Related Documentation

- [Setup Guide](../guides/setup.md) - Installation instructions
- [Architecture](../technical/architecture.md) - System design
- [Contributing](../CONTRIBUTING.md) - How to contribute
```

### 8.6 Audience-Based Organization

#### For Users (`docs/guides/`)
- **Setup guides**: Installation, configuration, getting started
- **Usage tutorials**: Basic usage, common workflows
- **Troubleshooting**: Common issues and solutions
- **Examples**: Practical usage examples

#### For Developers (`docs/technical/`)
- **Architecture docs**: System design, component relationships
- **API references**: Complete API documentation
- **Technical specs**: Performance, security, scalability
- **Integration guides**: Third-party integrations

#### For Contributors (`docs/development/`)
- **Development setup**: Environment configuration
- **Workflow guides**: Development processes
- **Code standards**: Style guides, conventions
- **Testing guides**: Testing strategies and tools

### 8.7 Duplicate Detection & Consolidation

1. **Content Analysis**: Compare file contents, not just names
2. **Version Comparison**: Keep most recent/complete version
3. **Merge Strategy**: Combine complementary content
4. **Archive Strategy**: Move superseded content to `docs/legacy/`
5. **Cross-Reference**: Update all links to point to consolidated version

---

## PHASE 9: GITHUB INTEGRATION

### 9.1 GitHub Actions CI/CD

**.github/workflows/ci.yml:**
```yaml
name: CI Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup environment
      uses: actions/setup-node@v4  # Or setup-python, etc.
      with:
        node-version: '18'
    
    - name: Install dependencies
      run: npm ci
    
    - name: Run tests
      run: npm test
    
    - name: Build
      run: npm run build

  build-release:
    needs: test
    if: startsWith(github.ref, 'refs/tags/')
    strategy:
      matrix:
        os: [macos-latest, windows-latest, ubuntu-latest]
    runs-on: ${{ matrix.os }}
    steps:
    - uses: actions/checkout@v4
    - run: npm ci
    - run: ./scripts/compile-build-dist.sh
    - uses: actions/upload-artifact@v4
      with:
        name: ${{ matrix.os }}-build
        path: dist/
```

### 9.2 Issue Templates

**.github/ISSUE_TEMPLATE/bug_report.md:**
```markdown
---
name: Bug report
about: Create a report to help us improve
title: '[BUG] '
labels: bug
---

**Describe the bug**
Clear description of the bug.

**To Reproduce**
Steps to reproduce:
1. Go to '...'
2. Click on '...'
3. See error

**Expected behavior**
What should happen.

**Screenshots**
If applicable.

**Environment:**
- OS: [e.g., macOS 13.0]
- Version: [e.g., 1.0.0]
```

**.github/ISSUE_TEMPLATE/feature_request.md:**
```markdown
---
name: Feature request
about: Suggest an idea
title: '[FEATURE] '
labels: enhancement
---

**Problem**
Description of the problem.

**Solution**
What you want to happen.

**Alternatives**
Other solutions considered.

**Additional context**
Any other context.
```

**.github/PULL_REQUEST_TEMPLATE.md:**
```markdown
## Description
Brief description of changes.

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation

## Testing
- [ ] Tests pass locally
- [ ] Added new tests

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No breaking changes
```

---

## PHASE 10: PORTFOLIO STANDARDIZATION (Multiple Projects)

### 10.1 Master Portfolio README
```markdown
# Development Portfolio

## 🚀 Featured Projects

### Project 1
[![Version](https://img.shields.io/badge/version-1.0.0-blue)]()
[![Status](https://img.shields.io/badge/status-active-green)]()

Description of the project.

**Tech Stack:** React, TypeScript, Electron
**Category:** Desktop Application
**[View Project →](./project1)**

### Project 2
[![Version](https://img.shields.io/badge/version-2.0.0-blue)]()
[![Status](https://img.shields.io/badge/status-active-green)]()

Description of the project.

**Tech Stack:** Python, CustomTkinter
**Category:** GUI Application
**[View Project →](./project2)**

## 📋 Standards
All projects follow consistent:
- Folder structure and organization
- Documentation standards
- Code quality standards
- Testing practices

## 🚀 Quick Start
```bash
# Clone portfolio
git clone [repository]

# Navigate to specific project
cd project-name

# Follow project README for setup
```

## 📊 Portfolio Statistics
- **Total Projects**: X
- **Languages**: Python, JavaScript, TypeScript, Swift
- **Platforms**: Web, Desktop, Mobile
- **Standards Compliance**: 100%
```

---

## PHASE 11: QUALITY VALIDATION

### 11.1 Standardization Quality Score (10 points)

**Documentation (3 points):**
- [ ] README.md with badges and clear sections (1)
- [ ] CONTRIBUTING, CODE_OF_CONDUCT, SECURITY (1)
- [ ] LICENSE and CHANGELOG with versioning (1)

**Structure (3 points):**
- [ ] Proper folder structure for tech stack (1)
- [ ] Source code organized in src/ (1)
- [ ] Tests organized with proper separation (1)

**Build & Automation (2 points):**
- [ ] Working build process with scripts/compile-build-dist.sh (1)
- [ ] CI/CD pipeline configured (1)

**Professional Presentation (2 points):**
- [ ] Clean README with screenshots (1)
- [ ] GitHub repository properly configured (1)

**Minimum passing: 8/10**

### 11.2 Validation Checklist

After reorganization:
```bash
# Show new structure
tree -L 3 -I 'node_modules|venv|__pycache__|.git'

# Verify project still works
[appropriate run command for the stack]

# Check for any broken imports
[appropriate lint command]
```

---

## PHASE 12: EXECUTION CHECKLIST

### Before Starting
- [ ] Created complete backup in backup/
- [ ] Verified backup contains all files
- [ ] Added backup/ to .gitignore

### Structure Creation
- [ ] Created all standard directories
- [ ] Created scripts/ folder
- [ ] Created dev/build-scripts/ folder
- [ ] Created run scripts in project root

### File Organization (MANUAL - NO SCRIPTS)
- [ ] Analyzed each file's content
- [ ] Moved source code to appropriate src/ subdirectories
- [ ] Organized documentation into docs/ hierarchy
- [ ] Moved assets to assets/ subdirectories (including icons)
- [ ] Archived old/deprecated files
- [ ] Moved tests to tests/ subdirectories

### Documentation
- [ ] Created/updated README.md
- [ ] Created tech-stack.md (then moved to dev/)
- [ ] Created CHANGELOG.md (then moved to dev/)
- [ ] Created CONTRIBUTING.md
- [ ] Created LICENSE
- [ ] Created .env.example
- [ ] Created claude.md (last)
- [ ] Created LEARNINGS.md
- [ ] Created TODO.md
- [ ] Created PROJECT_STATUS.md

### Build System
- [ ] Copied appropriate build templates to dev/build-scripts/
- [ ] Created scripts/compile-build-dist.sh from template
- [ ] Created all run-source-*.sh/bat scripts in root
- [ ] Created all run-*.sh/bat scripts in root
- [ ] Configured for macOS symlink creation
- [ ] Set executable permissions on all shell scripts

### GitHub Integration
- [ ] Created .github/workflows/ci.yml
- [ ] Created issue templates
- [ ] Created PR template

### Final Validation
- [ ] Achieved 8/10 or higher quality score
- [ ] Project builds successfully
- [ ] Tests pass
- [ ] Documentation complete
- [ ] Ready for collaboration

---

## USAGE INSTRUCTIONS FOR USER

1. Navigate to your project root directory
2. Copy this entire prompt
3. Paste to Claude and add: "Please standardize this project structure"
4. Review Claude's discovery findings
5. Approve the reorganization plan
6. Let Claude execute the changes
7. Verify your project still runs

## IMPORTANT NOTES

- **DO NOT CREATE NEW PRDs** - Only organize existing PRD files
- **NO SCRIPT-BASED FILE ORGANIZATION** - Manually analyze and move each file
- **BUILD SCRIPTS IN PROJECT** - All build templates stored in dev/build-scripts/
- **MAIN BUILD SCRIPT** - compile-build-dist.sh goes in scripts/
- **RUN SCRIPTS IN ROOT** - All run scripts stay in project root
- **CREATE MACOS SYMLINK** - After build, symlink to .app in root
- **ICONS IN ASSETS/ICONS** - All icon files go in assets/icons/ folder
- **MOVE DOCS AFTER CREATION** - tech-stack.md and CHANGELOG.md move to dev/
- **SELF-CONTAINED PROJECTS** - Each project contains its own build scripts

## CUSTOMIZATION

You can append specific requirements:
- "...and use snake_case for all files"
- "...and set up for TypeScript"
- "...and prepare for Docker deployment"
- "...but keep my existing folder names"
- "...and add GitHub Actions for [specific need]"

---

END OF PROMPT - EXECUTE STANDARDIZATION NOW