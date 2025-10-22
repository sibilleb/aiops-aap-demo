# Contributing to AIOps AAP Demo

Thank you for your interest in contributing to the AIOps Automation Platform Demo project! This document provides guidelines and instructions for contributing.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Submitting Changes](#submitting-changes)
- [Style Guidelines](#style-guidelines)
- [Testing](#testing)

## Code of Conduct

This project follows the [Red Hat Community Code of Conduct](https://www.redhat.com/en/about/code-of-conduct). By participating, you are expected to uphold this code.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the existing issues to avoid duplicates. When creating a bug report, include:

- **Clear title and description**
- **Steps to reproduce** the issue
- **Expected behavior** vs actual behavior
- **Environment details** (AAP version, LLM provider, etc.)
- **Logs or error messages** (sanitize any sensitive data)

### Suggesting Enhancements

Enhancement suggestions are welcome! Please provide:

- **Clear use case** - What problem does this solve?
- **Proposed solution** - How should it work?
- **Alternatives considered** - What other approaches did you consider?

### Contributing Code

We welcome pull requests for:

- Bug fixes
- New demo scenarios
- Improved prompts
- Additional LLM provider configurations
- Documentation improvements
- Custom modules and roles

## Development Setup

### Prerequisites

- Ansible Automation Platform 2.6+ (for testing)
- Python 3.9+
- Access to an LLM API endpoint
- Git

### Local Setup

1. **Fork and clone the repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/aiops-aap-demo.git
   cd aiops-aap-demo
   ```

2. **Create a local testing environment**
   ```bash
   mkdir local-testing
   cp ansible.cfg local-testing/
   ```

3. **Configure your LLM credentials**
   ```bash
   export LLM_ENDPOINT_URL="https://api.mistral.ai/v1/chat/completions"
   export LLM_API_KEY="your_api_key_here"
   export LLM_MODEL="mistral-large-latest"
   ```

4. **Test locally with ansible-playbook**
   ```bash
   ansible-playbook aiops/log_analysis.yml -e "log_scenario=banking"
   ```

## Submitting Changes

### Pull Request Process

1. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**
   - Follow the style guidelines below
   - Add tests if applicable
   - Update documentation

3. **Test your changes**
   - Test playbooks locally
   - Verify in AAP if possible
   - Check for syntax errors

4. **Commit your changes**
   ```bash
   git add .
   git commit -m "Add: brief description of changes"
   ```

5. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

6. **Create a Pull Request**
   - Use a clear, descriptive title
   - Reference any related issues
   - Provide detailed description of changes
   - Include testing evidence

### Commit Message Guidelines

Use clear, descriptive commit messages:

- **Add:** New features or files
- **Update:** Changes to existing functionality
- **Fix:** Bug fixes
- **Docs:** Documentation changes
- **Refactor:** Code restructuring without functional changes

Examples:
```
Add: New playbook for performance analysis
Update: Improved prompt engineering for log analysis
Fix: Resolve timeout issues with large log files
Docs: Update setup guide for Azure OpenAI
```

## Style Guidelines

### Ansible Playbook Style

- Use YAML format with 2-space indentation
- Follow [Ansible Best Practices](https://docs.ansible.com/ansible/latest/tips_tricks/ansible_tips_tricks.html)
- Use descriptive task names
- Include comments for complex logic
- Use variables for configurable values

Example:
```yaml
---
- name: Clear, descriptive playbook name
  hosts: localhost
  gather_facts: false

  vars:
    # Configuration variables
    llm_temperature: 0.5
    llm_max_tokens: 1500

  tasks:
    - name: Clear description of what this task does
      ansible.builtin.uri:
        url: "{{ lookup('env', 'LLM_ENDPOINT_URL') }}"
        # ... additional parameters
      register: result
```

### Python Style (for custom modules)

- Follow [PEP 8](https://pep8.org/)
- Use type hints where applicable
- Include docstrings for functions and classes
- Handle errors gracefully

### Documentation Style

- Use clear, concise language
- Include code examples where helpful
- Use proper markdown formatting
- Keep line length reasonable (80-100 chars)

### Prompt Engineering Guidelines

When modifying LLM prompts:

- **Be specific** - Clearly define the expected output
- **Provide structure** - Use numbered lists or sections
- **Include examples** - Show the format you want
- **Set context** - Explain the role and task
- **Test thoroughly** - Verify with multiple scenarios

Example:
```yaml
prompt: |
  You are an expert Site Reliability Engineer analyzing application logs.

  Analyze the following logs and provide:
  1. Summary of the issue (2-3 sentences)
  2. Root cause (if identifiable)
  3. Recommended actions (3-5 bullet points)

  LOGS:
  {{ log_content }}
```

## Testing

### Local Testing

Test your changes locally before submitting:

```bash
# Syntax check
ansible-playbook --syntax-check aiops/your_playbook.yml

# Dry run
ansible-playbook --check aiops/your_playbook.yml

# Full run
ansible-playbook aiops/your_playbook.yml
```

### AAP Testing

If you have access to AAP:

1. Import your branch as a project
2. Create a test job template
3. Run and verify outputs
4. Check for errors in job output

### Sample Data Testing

When adding new scenarios:

- Create representative sample data
- Test with various data sizes
- Verify token usage is reasonable
- Check output formatting

## Adding New Demos

To add a new demo scenario:

1. **Create sample data**
   ```bash
   mkdir -p files/your_scenario
   # Add sample files
   ```

2. **Create playbook**
   ```bash
   # aiops/your_scenario.yml
   ```

3. **Update documentation**
   - Add to README.md
   - Create docs entry if complex
   - Update setup.md with template instructions

4. **Test thoroughly**
   - Multiple LLM providers if possible
   - Various data sizes
   - Edge cases

5. **Submit PR** with:
   - Playbook
   - Sample data
   - Documentation
   - Example outputs

## Documentation Improvements

Documentation contributions are highly valued! Areas to improve:

- Clearer setup instructions
- More provider-specific examples
- Troubleshooting guides
- Video tutorials or screenshots
- Translation to other languages

## Questions?

- **Issues:** Open an issue for questions
- **Discussions:** Use GitHub Discussions for general questions
- **Email:** Contact bsibille@redhat.com for project-related inquiries

## License

By contributing, you agree that your contributions will be licensed under the Apache License 2.0.

---

Thank you for contributing to making IT Operations more intelligent and automated!
