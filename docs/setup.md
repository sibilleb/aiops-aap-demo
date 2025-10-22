# AIOps Demo - Complete Setup Guide

This guide walks you through setting up the AIOps demos in Ansible Automation Platform (AAP) 2.6+.

## Prerequisites

- Ansible Automation Platform 2.6 or later with admin access
- Access to an OpenAI-compatible LLM API endpoint (see [endpoint_config.md](endpoint_config.md))
- Git access to clone this repository
- Network connectivity from AAP to your LLM API endpoint

## Setup Overview

1. Create AAP Organization
2. Configure LLM API Credentials
3. Create Project from GitHub
4. Create Inventory
5. Create Job Templates
6. Test the Demos

---

## Step 1: Create Organization

Create a dedicated organization for AIOps demos:

**Via UI:**
- Navigate to **Organizations**
- Click **Add**
- Name: `AIOps Demos`
- Click **Save**

**Via API:**
```bash
curl -k -u "admin:password" \
  -H "Content-Type: application/json" \
  -X POST https://your-aap-url/api/controller/v2/organizations/ \
  -d '{"name": "AIOps Demos", "description": "AI-Powered IT Operations Demonstrations"}'
```

---

## Step 2: Configure Credentials

### 2.1 Create Custom Credential Type

**Via UI:**
- Navigate to **Credential Types**
- Click **Add**
- Name: `LLM API Credential`
- Input Configuration:
```yaml
fields:
  - id: endpoint_url
    type: string
    label: LLM API Endpoint URL
    help_text: Full URL to OpenAI-compatible API endpoint
  - id: api_key
    type: string
    label: API Key
    secret: true
  - id: model_name
    type: string
    label: Model Name
    help_text: Model identifier (e.g., mistral-large-latest)
required:
  - endpoint_url
  - api_key
  - model_name
```
- Injector Configuration:
```yaml
env:
  LLM_API_KEY: '{{ api_key }}'
  LLM_ENDPOINT_URL: '{{ endpoint_url }}'
  LLM_MODEL: '{{ model_name }}'
```
- Click **Save**

**Via API:**
```bash
curl -k -u "admin:password" \
  -H "Content-Type: application/json" \
  -X POST https://your-aap-url/api/controller/v2/credential_types/ \
  -d @llm_credential_type.json
```

Where `llm_credential_type.json` contains the configuration above.

### 2.2 Create LLM API Credential

**Via UI:**
- Navigate to **Credentials**
- Click **Add**
- Name: `Mistral API` (or your provider name)
- Organization: `AIOps Demos`
- Credential Type: `LLM API Credential`
- Fill in:
  - **LLM API Endpoint URL**: Your API endpoint
  - **API Key**: Your API key
  - **Model Name**: Model identifier
- Click **Save**

### 2.3 Create Machine Credential

You need a machine credential for localhost execution:

**Via UI:**
- Navigate to **Credentials**
- Click **Add**
- Name: `Local Execution`
- Organization: `AIOps Demos`
- Credential Type: `Machine`
- Username: Your username (or leave blank for current user)
- Click **Save**

---

## Step 3: Create Inventory

**Via UI:**
- Navigate to **Inventories**
- Click **Add** → **Add inventory**
- Name: `AIOps Demo Inventory`
- Organization: `AIOps Demos`
- Click **Save**
- Click **Hosts** tab
- Click **Add**
- Name: `localhost`
- Click **Save**

**Via API:**
```bash
# Create inventory
curl -k -u "admin:password" \
  -H "Content-Type: application/json" \
  -X POST https://your-aap-url/api/controller/v2/inventories/ \
  -d '{"name": "AIOps Demo Inventory", "organization": 2}'

# Add localhost host
curl -k -u "admin:password" \
  -H "Content-Type: application/json" \
  -X POST https://your-aap-url/api/controller/v2/hosts/ \
  -d '{"name": "localhost", "inventory": 2, "variables": "ansible_connection: local\nansible_python_interpreter: /usr/bin/python3"}'
```

---

## Step 4: Create Project

**Via UI:**
- Navigate to **Projects**
- Click **Add**
- Name: `AIOps Demo Project`
- Organization: `AIOps Demos`
- Source Control Type: `Git`
- Source Control URL: `https://github.com/sibilleb/aiops-aap-demo.git`
- Source Control Branch/Tag/Commit: `main`
- Options: Check **Update Revision on Launch**
- Click **Save**

**Via API:**
```bash
curl -k -u "admin:password" \
  -H "Content-Type: application/json" \
  -X POST https://your-aap-url/api/controller/v2/projects/ \
  -d '{
    "name": "AIOps Demo Project",
    "organization": 2,
    "scm_type": "git",
    "scm_url": "https://github.com/sibilleb/aiops-aap-demo.git",
    "scm_branch": "main",
    "scm_update_on_launch": true
  }'
```

Wait for the project to sync (check the **Projects** page for sync status).

---

## Step 5: Create Job Templates

Create four job templates, one for each demo scenario.

### 5.1 Log Analysis Template

**Via UI:**
- Navigate to **Templates**
- Click **Add** → **Add job template**
- Name: `AIOps: Log Analysis - Banking`
- Job Type: `Run`
- Inventory: `AIOps Demo Inventory`
- Project: `AIOps Demo Project`
- Playbook: `aiops/log_analysis.yml`
- Credentials:
  - `Mistral API` (LLM API Credential)
  - `Local Execution` (Machine)
- Variables:
```yaml
---
log_scenario: banking
```
- Options: Check **Enable Fact Storage**
- Click **Save**

Repeat for other log scenarios:
- `AIOps: Log Analysis - RHEL` with `log_scenario: rhel`
- `AIOps: Log Analysis - OpenShift` with `log_scenario: openshift`
- `AIOps: Log Analysis - Generic` with `log_scenario: generic`

### 5.2 Incident Summarization Template

- Name: `AIOps: Incident Summarization`
- Job Type: `Run`
- Inventory: `AIOps Demo Inventory`
- Project: `AIOps Demo Project`
- Playbook: `aiops/incident_summarization.yml`
- Credentials: Same as above
- Click **Save**

### 5.3 Alert Triage Template

- Name: `AIOps: Alert Triage`
- Job Type: `Run`
- Inventory: `AIOps Demo Inventory`
- Project: `AIOps Demo Project`
- Playbook: `aiops/alert_triage.yml`
- Credentials: Same as above
- Click **Save**

### 5.4 Runbook Generation Template

- Name: `AIOps: Runbook Generation`
- Job Type: `Run`
- Inventory: `AIOps Demo Inventory`
- Project: `AIOps Demo Project`
- Playbook: `aiops/runbook_generation.yml`
- Credentials: Same as above
- Variables:
```yaml
---
incident_description: "RDS database connection pool exhaustion causing payment failures"
service_name: "Payment Processing Service"
```
- Options: Check **Prompt on Launch** for Variables
- Click **Save**

---

## Step 6: Test the Demos

### Test Log Analysis
1. Navigate to **Templates**
2. Find `AIOps: Log Analysis - Banking`
3. Click the **Launch** button (rocket icon)
4. Wait for job to complete
5. Review the AI-generated analysis in the job output
6. Check `/tmp/aiops_log_analysis_*.txt` for the saved report

### Test Incident Summarization
1. Launch the `AIOps: Incident Summarization` template
2. Review the AI-generated ServiceNow ticket
3. Check `/tmp/servicenow_incident_*.txt` for the saved ticket

### Test Alert Triage
1. Launch the `AIOps: Alert Triage` template
2. Review the correlation analysis and priority rankings
3. Check `/tmp/alert_triage_*.txt` for the saved analysis

### Test Runbook Generation
1. Launch the `AIOps: Runbook Generation` template
2. Optionally modify the incident description and service name
3. Review the generated troubleshooting runbook
4. Check `/tmp/runbook_*.md` for the saved runbook

---

## Troubleshooting

### Issue: "Connection timeout to LLM API"
**Solution:** Check that AAP can reach your LLM endpoint:
```bash
curl -v https://your-llm-endpoint/v1/models
```

### Issue: "401 Unauthorized" from LLM API
**Solution:** Verify your API key is correct in the credential

### Issue: "Module 'ansible.builtin.uri' failed"
**Solution:** Check that the playbook has the correct environment variables set (LLM_ENDPOINT_URL, LLM_API_KEY, LLM_MODEL)

### Issue: "File not found" errors
**Solution:** Ensure the project synced successfully. Go to **Projects**, find your project, and click **Sync** to refresh.

### Issue: Token limits exceeded
**Solution:** Reduce `llm_max_tokens` in the playbook or use a model with higher limits

---

## Next Steps

- Read [endpoint_config.md](endpoint_config.md) for LLM provider-specific configuration
- Customize the prompts in the playbooks for your use cases
- Add organization-specific context to the system prompts
- Create workflows to chain multiple analyses together
- Integrate with ServiceNow, Jira, or other ITSM tools

---

## API-Based Setup Script

For automated setup, see the example scripts in the `local-testing/` directory (if you have repository access).

Complete API setup example:
```bash
#!/bin/bash
AAP_URL="https://your-aap-url"
AAP_USER="admin"
AAP_PASS="your-password"

# Create organization
curl -k -u "$AAP_USER:$AAP_PASS" \
  -H "Content-Type: application/json" \
  -X POST "$AAP_URL/api/controller/v2/organizations/" \
  -d '{"name": "AIOps Demos"}'

# Continue with credentials, inventory, project, and templates...
```

---

For questions or issues, please open an issue in the GitHub repository.
