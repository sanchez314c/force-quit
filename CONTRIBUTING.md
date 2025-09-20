# Contributing to ForceQUIT

Thank you for your interest in contributing to ForceQUIT! This guide will help you get started with contributing to our elegant macOS force quit utility.

## How to Contribute

### Reporting Bugs
1. Check if the bug has already been reported in [Issues](../../issues)
2. Create a detailed bug report including:
   - **Clear description** of the issue
   - **Steps to reproduce** the problem
   - **Expected behavior** vs actual behavior
   - **macOS version** and hardware (Intel/Apple Silicon)
   - **Screenshots or logs** if applicable
   - **ForceQUIT version** you're using

### Suggesting Features
1. Check existing [Issues](../../issues) and [Discussions](../../discussions) for similar requests
2. Create a feature request with:
   - **Problem it solves** for users
   - **Proposed solution** with UI/UX considerations
   - **Alternative solutions** you've considered
   - **Implementation considerations** (security, performance)

### Submitting Changes

#### Development Setup
1. **Requirements**: macOS 12.0+, Xcode 15.0+, Swift 5.9+
2. **Fork** the repository
3. **Clone** your fork locally
4. **Setup**: Run `./setup.sh` to prepare the development environment

#### Development Workflow
1. Create a **feature branch** from `main`:
   ```bash
   git checkout -b feature/amazing-new-feature
   ```
2. **Follow our conventions**:
   - Swift code style with SwiftLint compliance
   - MVVM architecture patterns
   - Security-first approach
   - Comprehensive testing

3. **Make your changes**:
   - Write clean, documented code
   - Add tests for new functionality
   - Update documentation as needed
   - Follow security best practices

4. **Test thoroughly**:
   ```bash
   swift test                     # Run unit tests
   ./scripts/build/test-automation.sh  # Run full test suite
   ```

5. **Build and validate**:
   ```bash
   ./scripts/compile-build-dist.sh     # Build universal binary
   ```

#### Code Standards
- **Swift Style**: Follow Apple's Swift API guidelines
- **Security**: All code must be SIP-compliant and sandbox-safe
- **Performance**: Consider memory usage and CPU efficiency
- **Testing**: Maintain >90% code coverage
- **Documentation**: Document all public APIs

#### SWARM Framework Integration
This project uses the SWARM 2.0 AI development framework. When contributing:
- Review `/swarm/` documentation for development patterns
- Use SWARM commands for complex development tasks
- Follow the 10-step SWARM development process for major features

#### Commit Guidelines
Use clear, descriptive commit messages:
```
feat: add shake detection for app activation
fix: resolve memory leak in process monitoring
docs: update API documentation for ProcessManager
test: add security validation test cases
```

#### Pull Request Process
1. **Update** your branch with the latest changes from `main`
2. **Test** your changes thoroughly
3. **Create** a pull request with:
   - Clear title and description
   - Reference to related issues
   - Screenshots for UI changes
   - Test results and performance impact

4. **Address feedback** from code review
5. **Ensure** all CI checks pass

### Development Guidelines

#### Security Requirements
- All privileged operations must use the helper tool architecture
- Never bypass macOS security mechanisms
- Validate all user inputs
- Follow principle of least privilege
- Test with SIP enabled

#### Performance Standards
- Startup time < 1 second
- Memory usage < 50MB baseline
- CPU usage < 5% during idle
- Responsive UI (60fps animations)

#### UI/UX Standards
- Follow Apple Human Interface Guidelines
- Dark mode first, with light mode support
- Accessibility compliance (VoiceOver, keyboard navigation)
- Intuitive user experience
- Visual feedback for all actions

### Getting Help

- **Questions**: Use [Discussions](../../discussions) for general questions
- **Documentation**: Check `/docs/` directory for technical details
- **SWARM Help**: See `/swarm/` directory for AI development framework
- **Security**: For security-related questions, see `/Sources/ForceQUITSecurity/`

### Code of Conduct
- Be respectful and inclusive
- Focus on constructive feedback
- Help newcomers learn and contribute
- Maintain professional communication

### Recognition
Contributors will be acknowledged in:
- `AUTHORS.md` file
- Release notes for their contributions
- Special recognition for significant contributions

Thank you for helping make ForceQUIT better! 🚀