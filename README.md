# AIOps Automation Platform Demo

**AI-Powered IT Operations Automation with Ansible Automation Platform**

## Overview

This repository demonstrates how to leverage Large Language Models (LLMs) for IT Operations automation using Ansible Automation Platform. The demos showcase real-world use cases including log analysis, incident management, alert triage, and automated runbook generation.

## Features

- 🔍 **Intelligent Log Analysis** - Automatically analyze application logs and identify root causes
- 📋 **Smart Incident Management** - Transform cryptic monitoring alerts into clear, actionable incident tickets
- 🚨 **Alert Triage Automation** - Batch process and prioritize monitoring alerts intelligently
- 📖 **Runbook Generation** - Generate troubleshooting guides from incident descriptions

## Architecture

This demo uses:
- **Ansible Automation Platform 2.6+** - Workflow orchestration and job execution
- **LLM APIs** (OpenAI-compatible) - AI-powered analysis and summarization
- **Ansible Custom Modules** - Reusable LLM integration components

## Quick Start

### Prerequisites

- Ansible Automation Platform 2.6 or later
- Access to an LLM API endpoint (Mistral, OpenAI, Azure OpenAI, etc.)
- Git access to clone this repository

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/sibilleb/aiops-aap-demo.git
   cd aiops-aap-demo
   ```

2. **Configure AAP**
   - Follow the detailed setup guide in [docs/setup.md](docs/setup.md)
   - Configure your LLM API credentials
   - Import the project into AAP

3. **Run your first demo**
   - Navigate to Job Templates in AAP
   - Launch "AIOps: Log Analysis - Banking" template
   - View the AI-generated analysis

## Demo Scenarios

### 1. Log Analysis
Analyzes various types of logs including:
- Banking/payment processing failures
- RHEL system errors
- OpenShift pod crashes
- Generic application errors

**Playbook:** `aiops/log_analysis.yml`

### 2. ServiceNow Incident AI
Converts cryptic monitoring alerts into clear ServiceNow incident tickets with:
- Clear subject lines
- Detailed descriptions
- Impact assessments
- Priority recommendations

**Playbook:** `aiops/incident_summarization.yml`

### 3. Alert Triage
Batch processes multiple alerts to:
- Classify severity
- Identify related alerts
- Suggest correlations
- Auto-acknowledge low priority items

**Playbook:** `aiops/alert_triage.yml`

### 4. Runbook Generation
Generates troubleshooting runbooks from incident descriptions

**Playbook:** `aiops/runbook_generation.yml`

## Repository Structure

```
aiops-aap-demo/
├── aiops/                  # Demo playbooks
├── roles/                  # Reusable Ansible roles
├── plugins/               # Custom modules and utilities
├── files/                 # Sample logs and data
├── docs/                  # Documentation
├── inventory/             # Inventory files
└── group_vars/            # Variable files
```

## LLM Provider Configuration

This demo works with any OpenAI-compatible API endpoint. See [docs/endpoint_config.md](docs/endpoint_config.md) for configuration details for:

- Mistral API
- OpenAI
- Azure OpenAI
- AWS Bedrock
- Red Hat OpenShift AI
- Self-hosted models (vLLM, Ollama)

## Documentation

- [Setup Guide](docs/setup.md) - Complete AAP configuration
- [Endpoint Configuration](docs/endpoint_config.md) - LLM provider setup
- [Custom Module Development](docs/custom_module_dev.md) - Extending the demos

## Implementation Approaches

This demo showcases TWO implementation methods:

### Basic Approach
Uses Ansible's built-in `uri` module for API calls
- Simple and portable
- No custom code required
- Great for learning

### Advanced Approach
Uses custom `aiops_llm_query` Ansible module
- Better error handling
- Token usage tracking
- Retry logic
- Production-ready

Both approaches are demonstrated side-by-side in the playbooks.

## Use Cases

- **DevOps Teams** - Accelerate incident response and troubleshooting
- **SRE Teams** - Automate alert triage and root cause analysis
- **IT Operations** - Generate documentation and runbooks automatically
- **Support Teams** - Summarize complex technical issues for stakeholders

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

Apache License 2.0 - See [LICENSE](LICENSE) for details.

## Support

For issues and questions:
- Open an issue in this repository
- Red Hat Ansible Automation Platform support channels

## Authors

**Blair Sibille** - Red Hat
- Email: bsibille@redhat.com
- GitHub: [@sibilleb](https://github.com/sibilleb)

---

**Note:** This is a demonstration project. Ensure you follow your organization's security and compliance policies when implementing AI/LLM integrations in production environments.
