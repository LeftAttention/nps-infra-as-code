# AWS Secrets Manager Playbook

This Ansible playbook is designed to manage secrets in AWS Secrets Manager. Its functionality includes creating new secrets, updating existing values, and appending new values to existing secrets. The playbook ensures that no existing values are deleted during this process.

## Features

### 1. Create New Secret
If the specified secret does not exist in AWS Secrets Manager, the playbook will create it with the provided key-value pairs.

#### Example
- **Provided Values**:
  ```yaml
  env_vars:
    username: "admin"
    password: "password123"
  ```
- **Resulting Secret**:
  ```json
  {
    "username": "admin",
    "password": "password123"
  }
  ```

### 2. Update Existing Values
If the specified secret already exists, the playbook will update any existing keys with new values provided.

#### Example
- **Existing Secret**:
  ```json
  {
    "username": "admin",
    "password": "oldpassword"
  }
  ```
- **Provided Values**:
  ```yaml
  env_vars:
    password: "newpassword123"
  ```
- **Resulting Secret**:
  ```json
  {
    "username": "admin",
    "password": "newpassword123"
  }
  ```

### 3. Append New Values
Any new key-value pairs provided will be added to the existing secret without removing any existing keys or values.

#### Example
- **Existing Secret**:
  ```json
  {
    "username": "admin"
  }
  ```
- **Provided Values**:
  ```yaml
  env_vars:
    password: "password123"
  ```
- **Resulting Secret**:
  ```json
  {
    "username": "admin",
    "password": "password123"
  }
  ```

## Prerequisites

- Ansible installed on your local machine.
- AWS CLI configured with appropriate permissions to access AWS Secrets Manager.
- The `community.aws` collection installed. You can install it using the command:
  ```bash
  ansible-galaxy collection install community.aws
  ```
- A `vars.yml` file containing the necessary variables:
  ```yaml
  aws_region: "your-aws-region"
  secret_name: "your-secret-name"
  env_vars:
    key1: "value1"
    key2: "value2"
  ```

## Variables

- `aws_region`: The AWS region where your secret is stored.
- `secret_name`: The name of the secret in AWS Secrets Manager.
- `env_vars`: A dictionary containing the environment variables (key-value pairs) to be appended or updated in the secret.

## Playbook Tasks

1. **Fetch the existing secret**:
   - The playbook attempts to fetch the existing secret from AWS Secrets Manager.
   - If the secret does not exist, the command will fail, but this is handled gracefully.

2. **Check if the secret was fetched successfully**:
   - Sets a fact (`secret_fetched`) to determine if the secret was retrieved successfully.

3. **Set existing secret fact**:
   - Converts the fetched secret from JSON format to a dictionary and sets it as a fact if the secret was fetched successfully.

4. **Merge new environment variables with existing secrets**:
   - Combines the existing secret with the new environment variables. New keys are added, and existing keys are updated with new values.

5. **Convert merged environment variables to JSON format**:
   - Converts the merged dictionary back to a JSON string for storage in AWS Secrets Manager.

6. **Create or update the secret in AWS Secrets Manager**:
   - Uses the `community.aws.aws_secret` module to create or update the secret with the new JSON string.

7. **Debug secret creation result**:
   - Outputs the result of the secret creation or update operation for debugging purposes.

## Usage

1. Update the `vars.yml` file with your AWS region, secret name, and the key-value pairs you want to manage.
2. Run the playbook using the following command:
   ```bash
   ansible-playbook main.yml
   ```

## Example `vars.yml`

```yaml
aws_region: "us-east-1"
secret_name: "my-secret"
env_vars:
  database_url: "mysql://user:password@localhost/db"
  api_key: "1234567890abcdef"
```

This playbook ensures that your secrets in AWS Secrets Manager are managed efficiently without any risk of accidental deletions. It appends new values and updates existing ones while preserving the integrity of existing secrets.