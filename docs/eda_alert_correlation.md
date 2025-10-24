# Event-Driven Ansible Alert Correlation

Complete guide for the EDA alert correlation use case with AI-powered incident creation.

---

## Overview

This use case demonstrates Event-Driven Ansible (EDA) receiving multiple correlated alerts from OpenShift/Kubernetes, analyzing them with AI, and automatically creating enriched ServiceNow incidents.

### Key Features

- ✅ Real-time alert ingestion via webhook
- ✅ Alert correlation by dependency tags
- ✅ AI-powered incident analysis and summarization
- ✅ Automatic ServiceNow incident creation
- ✅ Preserves all original alert data
- ✅ Modular playbook design (separate analysis and incident creation)
- ✅ Uses ServiceNow ITSM collection (not raw API)
- ✅ Configurable correlation windows
- ✅ Support for both batch and individual alerts

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│           Monitoring Systems (OpenShift/Kubernetes)            │
│                                                                 │
│  • Prometheus/Alertmanager                                      │
│  • OpenShift Platform Monitoring                                │
│  • Custom Alert Managers                                        │
└─────────────────────────────────────────────────────────────────┘
                             │
                             │ HTTP POST (JSON)
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│               Event-Driven Ansible Controller                   │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Webhook Source (Port 5000)                              │  │
│  │  Receives alert payloads                                 │  │
│  └──────────────────────────────────────────────────────────┘  │
│                             │                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Rulebook: alert_correlation.yml                         │  │
│  │                                                          │  │
│  │  Rules:                                                  │  │
│  │  • Match on dependency_tag                               │  │
│  │  • Batch mode (recommended)                              │  │
│  │  • Individual mode (with throttling)                     │  │
│  └──────────────────────────────────────────────────────────┘  │
│                             │                                   │
│                             │ Trigger Workflow                  │
│                             ▼                                   │
└─────────────────────────────────────────────────────────────────┘
                             │
┌─────────────────────────────────────────────────────────────────┐
│           Ansible Automation Platform Controller                │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Workflow: EDA Alert Correlation Workflow                │  │
│  └──────────────────────────────────────────────────────────┘  │
│                             │                                   │
│         ┌───────────────────┴───────────────────┐              │
│         ▼                                       ▼              │
│  ┌──────────────────┐                   ┌──────────────────┐  │
│  │  Job Template 1  │                   │  Job Template 2  │  │
│  │  Alert Analysis  │──── Success ─────▶│  Create Incident │  │
│  │                  │                   │                  │  │
│  │  Playbook:       │                   │  Playbook:       │  │
│  │  eda_alert_      │                   │  eda_create_     │  │
│  │  correlation.yml │                   │  snow_incident   │  │
│  │                  │                   │  .yml            │  │
│  │  • Analyze alerts│                   │  • Use ITSM      │  │
│  │  • Call LLM API  │                   │    collection    │  │
│  │  • Generate      │                   │  • Create        │  │
│  │    summaries     │                   │    incident      │  │
│  │  • set_stats     │                   │  • Return URL    │  │
│  └──────────────────┘                   └──────────────────┘  │
│         │                                       │              │
│         │ (calls)                               │ (calls)      │
│         ▼                                       ▼              │
└─────────────────────────────────────────────────────────────────┘
          │                                       │
          │ POST /chat                            │ POST /table/incident
          ▼                                       ▼
┌──────────────────┐                    ┌──────────────────┐
│   Mistral LLM    │                    │   ServiceNow     │
│   API            │                    │                  │
│                  │                    │  Incident        │
│  • Generate      │                    │  Created         │
│    short desc    │                    │                  │
│  • Analyze       │                    │  • AI-enhanced   │
│  • RCA           │                    │  • All alerts    │
└──────────────────┘                    │    preserved     │
                                        └──────────────────┘
```

---

## Components

### 1. EDA Rulebook (`eda/rulebooks/alert_correlation.yml`)

**Purpose:** Receives alerts via webhook and triggers AAP workflow

**Key Rules:**
- **Rule 1:** Process individual alerts with 30-second throttling
- **Rule 2:** Process batch of correlated alerts (recommended)
- **Rule 3:** Log unmatched alerts
- **Rule 4:** Health check endpoint

**Webhook Endpoint:** `http://[eda-host]:5000/endpoint`

**Expected Payload (Batch Mode):**
```json
{
  "dependency_tag": "payment-app-cluster-prod",
  "correlation_id": "incident-12345",
  "alerts": [
    {
      "alert_id": "alert-001",
      "dependency_tag": "payment-app-cluster-prod",
      "host": "ocp-worker-03.prod.example.com",
      "alert_name": "PodCrashLooping",
      "severity": "critical",
      "message": "Pod is in CrashLoopBackOff",
      ...
    },
    ...
  ],
  "metadata": {
    "source": "prometheus",
    "sent_at": "2025-10-24T16:30:00Z"
  }
}
```

### 2. Playbook 1: Alert Correlation & AI Analysis (`aiops/eda_alert_correlation.yml`)

**Purpose:** Analyze correlated alerts and generate AI summaries

**Process:**
1. Receive array of correlated alerts
2. Extract key information (severities, hosts, alert types)
3. Determine highest severity
4. Build comprehensive prompt with all alert details
5. Call LLM API for analysis (1200 tokens, 90s timeout)
6. Call LLM API for short description (100 tokens, 60s timeout)
7. Calculate ServiceNow priority/urgency/impact
8. Use `set_stats` to pass data to next workflow job

**Inputs:**
- `correlated_alerts`: Array of alert objects

**Outputs (via set_stats):**
- `ai_short_description`: Concise incident title
- `ai_full_analysis`: Detailed analysis with RCA
- `alert_details_table`: Formatted table of all alerts
- `incident_severity`: critical/warning/info
- `snow_priority/urgency/impact`: 1-5 values
- `dependency_tag`: Correlation key
- `alert_count`: Number of alerts
- `affected_hosts`: Comma-separated list

**Duration:** ~60-90 seconds

### 3. Playbook 2: Create ServiceNow Incident (`aiops/eda_create_snow_incident.yml`)

**Purpose:** Create SNOW incident using ITSM collection

**Process:**
1. Receive data from previous workflow job
2. Validate required fields
3. Build comprehensive incident description (AI analysis + alert details)
4. Use `servicenow.itsm.incident` module to create incident
5. Export incident details via `set_stats`
6. Display incident URL and summary

**Inputs (from workflow artifacts):**
- All outputs from Playbook 1 via `set_stats`

**Outputs:**
- ServiceNow incident created with:
  - AI-generated short description
  - AI analysis + original alerts in description
  - Appropriate priority/urgency/impact
  - Caller set to "Alert Integration"
  - u_ai_enriched = true

**Duration:** ~10-20 seconds

### 4. AAP Workflow Template

**Name:** AIOps: EDA Alert Correlation Workflow

**Structure:**
```
┌─────────────────────────────┐
│ Job Template 1              │
│ Alert Correlation & Analysis│
└─────────────────────────────┘
              │
              │ (on success)
              ▼
┌─────────────────────────────┐
│ Job Template 2              │
│ Create ServiceNow Incident  │
└─────────────────────────────┘
```

**Conditional Logic:**
- Job 2 only runs if Job 1 succeeds
- Job 2 receives data from Job 1 via workflow artifacts

### 5. Test Script (`local-testing/send_eda_alerts.sh`)

**Purpose:** Send test alerts to EDA webhook

**Modes:**
- `batch` (default): Send all alerts in one request
- `individual`: Send alerts one-by-one with 3s delays
- `health`: Test webhook connectivity

**Usage:**
```bash
cd local-testing
./send_eda_alerts.sh batch
```

---

## Setup Instructions

### Prerequisites

- Event-Driven Ansible Controller configured
- Ansible Automation Platform 2.6+
- ServiceNow instance with ITSM credentials
- LLM API access (Mistral or OpenAI-compatible)
- Network connectivity between EDA and AAP

### Step 1: Install Collections

Update `requirements.yml` and install collections:

```bash
ansible-galaxy collection install -r requirements.yml
```

Required collections:
- `servicenow.itsm`
- `ansible.eda`
- `community.general`

### Step 2: Create AAP Credentials

You already have:
- **Credential ID 7:** Mistral API (LLM)
- **Credential ID 8:** Local Execution
- **Credential ID 9:** ServiceNow API

No additional credentials needed for this use case.

### Step 3: Create AAP Job Templates

**Job Template 1: Alert Correlation & AI Analysis**
- Name: `AIOps: EDA Alert Correlation & Analysis`
- Project: AIOps Demo Project (ID=11)
- Playbook: `aiops/eda_alert_correlation.yml`
- Inventory: AIOps Demo Inventory (ID=2)
- Credentials: Mistral API (7), Local Execution (8)
- Extra Variables:
  ```yaml
  correlated_alerts: []
  ```
- Prompt on launch: Yes (for correlated_alerts)

**Job Template 2: Create ServiceNow Incident**
- Name: `AIOps: EDA Create ServiceNow Incident`
- Project: AIOps Demo Project (ID=11)
- Playbook: `aiops/eda_create_snow_incident.yml`
- Inventory: AIOps Demo Inventory (ID=2)
- Credentials: ServiceNow API (9), Local Execution (8)
- No extra variables (receives from workflow)

### Step 4: Create AAP Workflow Template

**Workflow Name:** `AIOps: EDA Alert Correlation Workflow`

**Nodes:**
1. **Node 1:** Job Template "Alert Correlation & Analysis"
   - Type: Job Template
   - Identifier: `alert-analysis`

2. **Node 2:** Job Template "Create ServiceNow Incident"
   - Type: Job Template
   - Identifier: `create-incident`

**Link:**
- From: `alert-analysis`
- To: `create-incident`
- Condition: `On Success`

### Step 5: Configure EDA Rulebook Activation

1. Navigate to EDA Controller UI
2. Create new Decision Environment (if needed):
   - Image: `quay.io/ansible/ansible-rulebook:latest`
3. Create new Rulebook Activation:
   - Name: `AIOps Alert Correlation`
   - Project: AIOps Demo Project
   - Rulebook: `eda/rulebooks/alert_correlation.yml`
   - Decision Environment: Select your environment
   - AWX Token: Create token for EDA to call AAP
   - Restart Policy: On failure
   - Enable: Yes

4. Verify activation is running:
   - Status: Running
   - Webhook URL: `http://[eda-host]:5000/endpoint`

### Step 6: Configure Monitoring Systems

Update your monitoring systems (Prometheus, Alertmanager, etc.) to send alerts to EDA webhook:

**Alertmanager webhook_configs example:**
```yaml
receivers:
  - name: eda-webhook
    webhook_configs:
      - url: 'http://eda-controller.example.com:5000/endpoint'
        send_resolved: false
```

**Batch payload format:**
```json
{
  "dependency_tag": "{{ .CommonLabels.service }}",
  "alerts": [
    {
      "alert_id": "{{ .GroupLabels.alertname }}-{{ .StartsAt }}",
      "dependency_tag": "{{ .CommonLabels.service }}",
      "host": "{{ .Labels.instance }}",
      "alert_name": "{{ .Labels.alertname }}",
      "severity": "{{ .Labels.severity }}",
      "message": "{{ .Annotations.summary }}",
      "timestamp": "{{ .StartsAt }}"
    }
  ]
}
```

---

## Testing

### Test 1: Health Check

```bash
cd local-testing
./send_eda_alerts.sh health
```

Expected output:
```
✓ EDA webhook is responding (HTTP 200)
```

### Test 2: Batch Alert Correlation (Recommended)

```bash
cd local-testing
./send_eda_alerts.sh batch
```

**What happens:**
1. Script sends 5 correlated OpenShift alerts in one request
2. EDA receives batch and triggers workflow
3. Job 1 analyzes alerts (~60-90 seconds)
4. Job 2 creates SNOW incident (~10-20 seconds)
5. Total: ~2-3 minutes

**Verify:**
1. Check AAP Jobs page for workflow execution
2. Check ServiceNow for new incident:
   - Caller: Alert Integration
   - Short description: AI-generated summary
   - Description: Full analysis + all alert details
   - u_ai_enriched: true

### Test 3: Individual Alerts with Throttling

```bash
cd local-testing
./send_eda_alerts.sh individual
```

**What happens:**
1. Script sends 5 alerts individually (3s delays)
2. EDA throttles to trigger workflow only once per 30s per dependency_tag
3. Only one workflow execution despite 5 alerts

**Verify:**
1. Check AAP Jobs - should see only ONE workflow execution
2. Demonstrates throttling prevents duplicate incidents

---

## Data Flow

### 1. Alert Reception

**EDA Webhook receives:**
```json
{
  "dependency_tag": "payment-app-cluster-prod",
  "alerts": [
    { "alert_id": "001", "severity": "critical", ... },
    { "alert_id": "002", "severity": "warning", ... },
    ...
  ]
}
```

### 2. Workflow Trigger

**EDA triggers workflow with:**
```yaml
extra_vars:
  correlated_alerts:
    - alert_id: "001"
      severity: "critical"
      ...
    - alert_id: "002"
      severity: "warning"
      ...
  correlation_id: "auto-1698156789"
  dependency_tag: "payment-app-cluster-prod"
```

### 3. Job 1: Analysis

**Playbook processes alerts:**
- Extracts: dependency_tags, severities, hosts, alert names
- Determines: highest severity (critical/warning/info)
- Calls LLM: Generates analysis and short description
- Calculates: SNOW priority/urgency/impact
- Exports via set_stats

**LLM Prompt includes:**
- All alert details
- Timestamps
- Severity levels
- Request for structured analysis

**LLM Response includes:**
- Short description (100 chars)
- Detailed analysis
- Root cause possibilities
- Impact assessment
- Recommended actions

### 4. Job 2: Incident Creation

**Playbook receives from Job 1:**
- ai_short_description
- ai_full_analysis
- alert_details_table
- incident_severity
- snow_priority/urgency/impact

**Playbook creates incident:**
```python
servicenow.itsm.incident:
  state: new
  short_description: "{{ ai_short_description }}"
  description: "{{ ai_analysis + alert_details }}"
  urgency: high
  impact: high
  priority: critical
  caller: "Alert Integration"
  other:
    u_ai_enriched: true
```

**ServiceNow incident created with:**
- AI-enhanced short description
- Comprehensive description (AI + raw alerts)
- Appropriate priority
- All original alert data preserved

---

## Troubleshooting

### Issue: EDA Webhook Not Responding

**Symptoms:**
- Test script returns connection refused
- `curl` to webhook fails

**Checks:**
1. Verify rulebook activation is running:
   ```
   EDA UI → Rulebook Activations → Status: Running
   ```
2. Check EDA logs:
   ```bash
   oc logs -n aap deployment/eda-controller -f
   ```
3. Verify port 5000 is open:
   ```bash
   nc -zv eda-controller 5000
   ```

**Fix:**
- Restart rulebook activation
- Check firewall rules
- Verify decision environment is healthy

### Issue: Workflow Not Triggered

**Symptoms:**
- Webhook returns 200 but no workflow starts
- No jobs appear in AAP

**Checks:**
1. Check EDA audit logs:
   ```
   EDA UI → Audit → Recent events
   ```
2. Verify rulebook syntax:
   ```bash
   ansible-rulebook --check -r eda/rulebooks/alert_correlation.yml
   ```
3. Check EDA → AAP connection:
   - Verify AWX token is valid
   - Test AAP connectivity from EDA

**Fix:**
- Update AWX token in rulebook activation
- Verify workflow template exists and is enabled
- Check AAP API connectivity

### Issue: Job 1 Fails with LLM Timeout

**Symptoms:**
- Job fails with "The read operation timed out"
- LLM API takes >90 seconds

**Checks:**
1. Review alert count - too many alerts?
2. Check LLM API status
3. Review prompt length

**Fix:**
- Reduce `llm_max_tokens` from 1200 to 800
- Increase timeout from 90s to 120s
- Split into smaller correlation groups

### Issue: Job 2 Fails - ServiceNow Module Error

**Symptoms:**
- Error: "servicenow.itsm.incident module not found"

**Checks:**
1. Verify collection installed:
   ```bash
   ansible-galaxy collection list | grep servicenow
   ```
2. Check execution environment has collection

**Fix:**
- Install collection:
  ```bash
  ansible-galaxy collection install servicenow.itsm
  ```
- Update execution environment to include collection

### Issue: Workflow Data Not Passed Between Jobs

**Symptoms:**
- Job 2 fails with "Missing required data"
- Variables from Job 1 not available

**Checks:**
1. Verify Job 1 uses `set_stats` with `per_host: false`
2. Check workflow configuration allows artifact passing

**Fix:**
- Ensure workflow template has "Enable artifact" checked
- Verify `set_stats` in Job 1 playbook

### Issue: Duplicate Incidents Created

**Symptoms:**
- Same alerts create multiple incidents
- Throttling not working

**Checks:**
1. Verify throttle configuration in rulebook
2. Check `dependency_tag` values match exactly

**Fix:**
- Ensure all related alerts have identical `dependency_tag`
- Increase throttle window from 30s to 60s

---

## Performance Considerations

### Timing

**Expected Durations:**
- Alert ingestion: <1 second
- EDA processing: <2 seconds
- Job 1 (Analysis): 60-90 seconds
- Job 2 (Incident): 10-20 seconds
- **Total: 2-3 minutes** from alert to incident

### Scaling

**Alert Volume:**
- Low (<10/min): Default configuration works
- Medium (10-100/min): Consider increasing workers
- High (>100/min): Use message queue (RabbitMQ/Kafka)

**Concurrent Workflows:**
- AAP can handle multiple workflows simultaneously
- Each correlation group triggers independent workflow
- No blocking between different dependency_tags

### Resource Usage

**LLM API Costs:**
- ~1200-1500 tokens per correlation analysis
- Cost varies by provider (Mistral, OpenAI, etc.)
- Monitor `llm_tokens_used` in playbook output

**AAP Execution Nodes:**
- Each workflow uses 2 execution slots (2 jobs)
- Plan capacity based on expected alert volume

---

## Security Considerations

### Webhook Security

**Current (Demo):**
- No authentication on webhook
- Open to localhost only

**Production Recommendations:**
- Add webhook token authentication
- Use HTTPS with valid certificates
- Implement IP allowlisting
- Rate limiting

**Example secure rulebook:**
```yaml
sources:
  - ansible.eda.webhook:
      host: 0.0.0.0
      port: 5000
      token: "{{ lookup('env', 'WEBHOOK_TOKEN') }}"
      ssl: true
      cert: /path/to/cert.pem
      key: /path/to/key.pem
```

### Credential Management

- LLM API keys stored in AAP credentials
- ServiceNow passwords encrypted
- No secrets in rulebooks or playbooks
- Use AAP credential injection

### Data Privacy

- Alert data may contain sensitive information
- ServiceNow incidents inherit SNOW's access controls
- LLM providers may log API requests
- Consider on-premise LLM for sensitive data

---

## Sample Output

### EDA Log Output

```
[2025-10-24 16:30:05] INFO: Webhook received POST to /endpoint
[2025-10-24 16:30:05] INFO: Event matched rule: Process batch of correlated alerts
[2025-10-24 16:30:05] INFO: Triggering workflow: AIOps: EDA Alert Correlation Workflow
[2025-10-24 16:30:06] INFO: Workflow job 1234 launched successfully
```

### Job 1 Output

```
TASK [Display correlation information]
ok: [localhost] => {
    "msg": [
        "========================================",
        "AIOps EDA Alert Correlation & Analysis",
        "========================================",
        "Number of correlated alerts: 5",
        "Correlation started: 2025-10-24T16:30:10.123Z",
        "========================================"
    ]
}

TASK [Call LLM API for correlated alert analysis]
ok: [localhost]

TASK [Display analysis summary]
ok: [localhost] => {
    "msg": [
        "========================================",
        "AI ANALYSIS COMPLETE",
        "========================================",
        "Short Description: Production Payment Service: Multiple Pod Failures and Resource Exhaustion",
        "Alert Count: 5",
        "Severity: critical",
        "SNOW Priority: 1",
        "LLM Tokens Used: 1456",
        "========================================",
        "",
        "Data exported via set_stats for next workflow job",
        "Next: Create ServiceNow incident with AI-enhanced content"
    ]
}
```

### Job 2 Output

```
TASK [Create incident in ServiceNow using ITSM module]
changed: [localhost]

TASK [Display incident creation result]
ok: [localhost] => {
    "msg": [
        "=========================================",
        "SERVICENOW INCIDENT CREATED SUCCESSFULLY",
        "=========================================",
        "Incident Number: INC0010042",
        "Incident Sys ID: 9a8b7c6d5e4f3g2h1i0j",
        "State: New",
        "Priority: 1 - Critical",
        "Urgency: 1 - High",
        "Impact: 1 - High",
        "Created On: 2025-10-24 16:32:15",
        "=========================================",
        "",
        "View incident in ServiceNow:",
        "https://ven05174.service-now.com/nav_to.do?uri=incident.do?sys_id=9a8b7c6d5e4f3g2h1i0j",
        "",
        "Incident Summary:",
        "• Correlated 5 alerts",
        "• Affected hosts: ocp-worker-03, ocp-worker-05, ocp-master-01",
        "• Dependency tag: payment-app-cluster-prod",
        "• AI analysis: 1456 tokens",
        "========================================="
    ]
}
```

---

## Next Steps

### Enhancements

1. **Add Alert Deduplication**
   - Store recent alerts in Redis/database
   - Detect true duplicates vs. related alerts

2. **Implement Smart Throttling**
   - Dynamic window based on alert volume
   - Separate windows per severity level

3. **Add Notification Integration**
   - Slack/Teams notifications when incident created
   - PagerDuty integration for high-priority incidents

4. **Historical Analysis**
   - Compare with past similar incidents
   - Suggest solutions based on previous resolutions

5. **Auto-Assignment**
   - Route incidents to appropriate teams
   - Based on alert sources, namespaces, severity

6. **Metrics Dashboard**
   - Track alert volumes by dependency_tag
   - Monitor MTTR (Mean Time To Resolution)
   - LLM API cost analysis

---

## References

- [Event-Driven Ansible Documentation](https://access.redhat.com/documentation/en-us/red_hat_ansible_automation_platform/2.4/html/event-driven_ansible_controller_user_guide)
- [ServiceNow ITSM Collection](https://console.redhat.com/ansible/automation-hub/repo/published/servicenow/itsm)
- [AAP Workflow Documentation](https://docs.ansible.com/automation-controller/latest/html/userguide/workflows.html)

---

*Last Updated: 2025-10-24*
*Status: Ready for Testing*
