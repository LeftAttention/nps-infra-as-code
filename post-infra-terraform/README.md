# Post-Deployment Steps: Creating DNS Record for ALB

### Overview
After deploying main infrastructure with Terraform, Helm is used in CI/CD pipeline to deploy an application, which creates an ALB (Application Load Balancer) as an Ingress resource. This post-deployment step involves creating a DNS record for the ALB in Cloudflare to enable access to application via a human-readable domain name.

### Purpose
- **Access Control**: A DNS record allows users to access your application using a domain name instead of an IP address.
- **Load Balancer Routing**: Directs incoming traffic to the ALB, ensuring high availability and scalability of your application.

### Approach
Instead of including this step in the main Terraform infrastructure deployment, it's handled separately due to the dynamic nature of Helm deployments in the CI/CD pipeline.

### Execution Flow
1. **Main Infrastructure Deployment**: Terraform deploys the foundational infrastructure components (e.g., VPC, subnets, security groups) but does not include specific application resources like the ALB.
2. **CI/CD Pipeline Deployment**:
   - Helm is utilized in the CI/CD pipeline to deploy the application, which creates the ALB as an Ingress resource.
   - The pipeline triggers a post-deployment step to create a DNS record for the ALB in Cloudflare.
3. **DNS Record Creation**:
   - Terraform, triggered by the CI/CD pipeline or an external event, creates the DNS record in Cloudflare using the ALB's DNS name obtained dynamically.
   - This DNS record points to the ALB, enabling users to access the application via a custom domain.

### Advantages
- **Separation of Concerns**: Decouples application deployment from infrastructure provisioning, allowing flexibility in managing application-specific resources.
- **Scalability**: Scales seamlessly with dynamic Helm deployments, ensuring that DNS records are created only when necessary.
- **Automation**: Automates the DNS record creation process, reducing manual intervention and ensuring consistency.



### Steps
1. **Review Terraform Configuration**:
   Ensure that your Terraform configuration includes the necessary providers for AWS and Cloudflare, as well as variables and resources required for creating the DNS record.

2. **Update Terraform Variables**:
   Make sure to update the Terraform variables according to your environment. These variables typically include:
   - `aws_region`: AWS region where the ALB is deployed.
   - `account_id`: Your AWS account ID.
   - `alb_name`: Name of the ALB deployed by Helm.
   - `domain_name`: Prefix of the domain where you want to create the DNS record.
   - `cloudflare_zone_name`: Name of the Cloudflare zone.
   - `cloudflare_secret_name`: Name of the Cloudflare secret containing the API key.

3. **Run Terraform**:
   Execute the Terraform configuration to create the DNS record. Ensure that you are in the correct directory containing your Terraform files.

   ```bash
   terraform init
   terraform apply
   ```

4. **Verify DNS Record**:
   After Terraform completes execution, verify that the DNS record has been created in your Cloudflare dashboard. The record should point to the ALB's DNS name.