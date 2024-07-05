Sure, here's a README file that includes instructions on how to use the provided Ansible playbook to create an AWS Secrets Manager secret from environment variables, as well as how to obtain the Discord URL:

---

## AWS Secrets Manager Setup

### Prerequisites
- Ensure you have Ansible installed on your local machine.

### Usage
1. Clone this repository to your local machine.
2. Update the `env_vars.yml` file with your desired environment variables. You can use the provided template as a reference.
3. Run the Ansible playbook to create the secret:
    ```bash
    ansible-playbook create_secret.yml
    ```
4. Verify that the secret was created successfully in AWS Secrets Manager.

---

## Obtaining Discord URL

To obtain the Discord URL, follow these steps:

1. Log in to your Discord account.
2. Navigate to your server/channel where you want to generate the webhook URL.
3. Go to Server Settings > Integrations > Webhooks.
4. Click on "Create Webhook" and follow the prompts to set up the webhook.
5. Once the webhook is created, copy the URL provided.

---

### `env_vars.yml` Template

```yaml
env_vars:
  APPLICATION_ALERT_CHANNEL: ""
  CLUSTER_ALERT_CHANNEL: ""
  PIPELINE_ALERT_CHANNEL: ""
```