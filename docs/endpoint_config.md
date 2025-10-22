# LLM Endpoint Configuration Guide

This guide provides configuration details for various LLM providers with OpenAI-compatible API endpoints.

## Overview

The AIOps demos use the OpenAI Chat Completions API format, which is widely supported. You'll need three pieces of information:

1. **Endpoint URL** - The full API endpoint URL
2. **API Key** - Authentication token for the service
3. **Model Name** - The specific model identifier to use

---

## Mistral API

### Configuration

- **Endpoint URL**: `https://api.mistral.ai/v1/chat/completions`
- **API Key**: Get from [console.mistral.ai](https://console.mistral.ai)
- **Model Name**:
  - `mistral-large-latest` (recommended for complex analysis)
  - `mistral-medium-latest` (balanced performance/cost)
  - `mistral-small-latest` (cost-effective for simpler tasks)

### Example Credential
```yaml
LLM_ENDPOINT_URL: https://api.mistral.ai/v1/chat/completions
LLM_API_KEY: your_mistral_api_key_here
LLM_MODEL: mistral-large-latest
```

---

## OpenAI

### Configuration

- **Endpoint URL**: `https://api.openai.com/v1/chat/completions`
- **API Key**: Get from [platform.openai.com](https://platform.openai.com)
- **Model Name**:
  - `gpt-4o` (latest GPT-4, recommended)
  - `gpt-4-turbo` (fast, capable)
  - `gpt-3.5-turbo` (cost-effective)

### Example Credential
```yaml
LLM_ENDPOINT_URL: https://api.openai.com/v1/chat/completions
LLM_API_KEY: sk-...your_openai_key...
LLM_MODEL: gpt-4o
```

---

## Azure OpenAI

### Configuration

- **Endpoint URL**: `https://{your-resource-name}.openai.azure.com/openai/deployments/{deployment-name}/chat/completions?api-version=2024-02-01`
- **API Key**: Get from Azure Portal → Your OpenAI resource → Keys and Endpoint
- **Model Name**: Your deployment name (e.g., `gpt-4`)

### Example Credential
```yaml
LLM_ENDPOINT_URL: https://my-company-openai.openai.azure.com/openai/deployments/gpt-4-deployment/chat/completions?api-version=2024-02-01
LLM_API_KEY: your_azure_openai_key_here
LLM_MODEL: gpt-4
```

---

## AWS Bedrock

### Configuration

AWS Bedrock requires a proxy or wrapper to convert to OpenAI format. Options:

1. **Use AWS Bedrock Proxy** (e.g., [aws-bedrock-proxy](https://github.com/your-proxy-project))
2. **Use LiteLLM** as a proxy

### Example with LiteLLM Proxy

```yaml
LLM_ENDPOINT_URL: http://your-litellm-proxy:8000/chat/completions
LLM_API_KEY: your_litellm_key
LLM_MODEL: bedrock/anthropic.claude-3-sonnet-20240229-v1:0
```
---

## Red Hat OpenShift AI (RHOAI)

**Recommended for:** On-premise deployments, air-gapped environments

### Configuration

RHOAI can serve models with OpenAI-compatible endpoints using vLLM or TGI.

- **Endpoint URL**: `https://your-model-route/v1/chat/completions`
- **API Key**: Token from RHOAI (if authentication enabled)
- **Model Name**: Depends on deployed model

### Example Credential
```yaml
LLM_ENDPOINT_URL: https://mistral-7b-vllm-aiops.apps.cluster.example.com/v1/chat/completions
LLM_API_KEY: your_rhoai_token
LLM_MODEL: mistralai/Mistral-7B-Instruct-v0.2
```

### Notes
- Model name may be ignored by vLLM (uses deployed model)
- Can deploy behind OpenShift Route with TLS
- No external API calls - fully on-premise

---

## Ollama (Local Development)

### Configuration

Ollama doesn't natively support OpenAI format, but you can:

1. Use Ollama with LiteLLM proxy
2. Use Ollama's OpenAI compatibility mode (if available in newer versions)

### Example with LiteLLM
```yaml
LLM_ENDPOINT_URL: http://localhost:8000/chat/completions
LLM_API_KEY: anything
LLM_MODEL: ollama/mistral
```

---

## Self-Hosted with vLLM

**Recommended for:** Custom deployments, fine-tuned models

### Configuration

vLLM provides OpenAI-compatible API out of the box.

- **Endpoint URL**: `http://your-vllm-server:8000/v1/chat/completions`
- **API Key**: Optional (configure with `--api-key` flag when starting vLLM)
- **Model Name**: The model loaded in vLLM

### Example Credential
```yaml
LLM_ENDPOINT_URL: http://vllm-server.internal:8000/v1/chat/completions
LLM_API_KEY: your_vllm_api_key
LLM_MODEL: mistralai/Mistral-7B-Instruct-v0.2
```

### Starting vLLM with API Key
```bash
python -m vllm.entrypoints.openai.api_server \
  --model mistralai/Mistral-7B-Instruct-v0.2 \
  --api-key your_vllm_api_key
```

### Notes
- Excellent performance with proper GPU setup
- Supports continuous batching for efficiency
- Can serve custom fine-tuned models

---

## Testing Your Configuration

After configuring your LLM credential in AAP, test it with a simple playbook:

```yaml
---
- name: Test LLM Connection
  hosts: localhost
  gather_facts: false
  tasks:
    - name: Test LLM API
      ansible.builtin.uri:
        url: "{{ lookup('env', 'LLM_ENDPOINT_URL') }}"
        method: POST
        headers:
          Authorization: "Bearer {{ lookup('env', 'LLM_API_KEY') }}"
          Content-Type: "application/json"
        body_format: json
        body:
          model: "{{ lookup('env', 'LLM_MODEL') }}"
          messages:
            - role: user
              content: "Say 'hello' if you can read this"
          max_tokens: 50
        status_code: 200
        timeout: 30
        validate_certs: false
      register: test_response

    - name: Display response
      ansible.builtin.debug:
        msg: "{{ test_response.json.choices[0].message.content }}"
```

---

## Cost Optimization Tips

### 1. Choose the Right Model
- Use smaller models (Mistral Small, GPT-3.5) for simpler tasks
- Reserve large models for complex analysis

### 2. Adjust Token Limits
```yaml
llm_max_tokens: 1000  # Reduce for simpler outputs
```

### 3. Increase Temperature for Variety
```yaml
llm_temperature: 0.3  # Lower = more focused, less creative = fewer tokens
```

### 4. Cache Responses
- Save analysis outputs to avoid re-analyzing same logs
- Use AAP fact caching

### 5. Batch Operations
- Process multiple items in one request when possible
- Use alert triage for bulk analysis

---

## Security Best Practices

### 1. Credential Management
- Store API keys in AAP credentials (encrypted)
- Never commit API keys to version control
- Rotate keys regularly

### 2. Network Security
- Use HTTPS endpoints only
- Consider using private endpoints for cloud providers
- Implement firewall rules to restrict AAP → LLM traffic

### 3. Data Privacy
- Review your LLM provider's data retention policy
- For sensitive data, use on-premise or private deployments
- Consider using Azure OpenAI with data processing addendum

### 4. Rate Limiting
- Implement rate limiting in playbooks
- Use AAP's concurrency controls
- Monitor token usage

---

## Troubleshooting

### Issue: SSL Certificate Errors
```yaml
# In playbook uri module call:
validate_certs: false  # Only for self-signed certs in dev
```

### Issue: Connection Timeouts
```yaml
# Increase timeout:
timeout: 120  # seconds
```

### Issue: Rate Limit Errors
- Implement retry logic with exponential backoff
- Reduce concurrency in AAP job settings
- Upgrade LLM API tier

### Issue: "Model not found"
- Verify model name is correct for your provider
- Check model is available in your region (Azure)
- Ensure deployment exists (Azure, RHOAI)


---

## Next Steps

1. Choose your LLM provider based on requirements
2. Configure the credential in AAP following [setup.md](setup.md)
3. Test with a simple demo
4. Customize prompts and parameters for your use cases
5. Monitor costs and performance

For questions about specific providers, consult their documentation or open an issue in this repository.
