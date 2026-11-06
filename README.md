# it-vedant cloud deployment demos

This repository contains a small, tested Python application and three AWS/Terraform demos built on a shared network foundation:

| Stack | What it creates |
| --- | --- |
| `terraform/network` | A two-AZ VPC, public/private subnets, internet gateway, and NAT gateway |
| `terraform/eks` | Private EKS workers, ECR, and a GitHub Actions OIDC deploy role |
| `terraform/cloudfront` | A private S3 static-site bucket, CloudFront Origin Access Control (OAC), and an HTTPS distribution |
| `terraform/asg` | A public ALB, private EC2 Auto Scaling group, health replacement, and 70% CPU target tracking |

Each infrastructure stack has its own state key in the existing S3 bucket `devops-user-terraform-state-backend` (region `ap-south-1`). The EKS and ASG stacks read the shared VPC outputs from the network state and do not create duplicate networks. CloudFront is independent and does not use a VPC.

## Prerequisites

- An AWS account with permission to create the listed resources and IAM roles.
- AWS CLI v2, Terraform 1.10+, Docker Desktop, and `kubectl`.
- A GitHub repository at `Rahilz313/it-vedant` (update the repository name in the workflow trust configuration if it changes).
- For deploying the app, GitHub Actions enabled and the repository's default deployment branch set to `main`.

The default AWS region is `ap-south-1`; change `aws_region` in the relevant root before applying if needed. EKS Kubernetes version is configurable in `terraform/eks/variables.tf`; select a version currently offered by EKS in your region.

## Credentials: local development and GitHub Actions

Do not put AWS access keys in Terraform files, `.tfvars`, Docker images, GitHub variables, or this repository. For local work, use AWS IAM Identity Center (AWS SSO) and the AWS CLI credential cache:

```powershell
aws configure sso --profile devops-user
aws sso login --profile devops-user
$env:AWS_PROFILE = "devops-user"
aws sts get-caller-identity
```

Use an IAM Identity Center permission set that can manage the demo resources and their IAM roles. Terraform and the AWS CLI use the temporary SSO credentials from that profile. They expire and are refreshed by `aws sso login`; no access key or secret key is stored in this project. In a managed environment, assume the organization's approved role instead.

**Do not run Terraform as the AWS account root user.** Before applying anything, confirm `aws sts get-caller-identity` returns an assumed role or federated identity, not an ARN ending in `:root`. If you previously created root access keys, stop using them; enable root MFA, remove the root access key in the AWS console, and switch to SSO. The assigned SSO permission set must allow the lab's required resource and IAM operations.

GitHub Actions uses the account-level `token.actions.githubusercontent.com` OIDC provider, which Terraform looks up but does not manage. Terraform creates a separate IAM deploy role for this repository, with trust restricted to its configured branch and permissions scoped to this project's ECR repository and EKS cluster. The provider can remain shared with other repositories and workflows. No static AWS secrets or Vault are needed.

## Deployment order

Do the foundation first and verify it before moving on:

1. Configure local AWS SSO credentials (no access keys in the project).
2. Verify the existing Terraform state bucket has block-public-access enabled, default encryption enabled, and versioning enabled.
3. Configure the S3 backend and create/inspect the shared VPC in `terraform/network`.
4. Deploy `terraform/eks`; it creates a repository-scoped GitHub OIDC role and deploys the app.
5. Deploy `terraform/cloudfront` independently when ready to serve the static page.
6. Deploy `terraform/asg` independently when ready to demonstrate EC2/ALB scaling.

CloudFront is not a layer in front of this EKS service in the current design. The two example flows are:

```text
Container app:
GitHub push -> Actions tests -> Docker build -> GitHub OIDC role
  -> ECR image -> EKS deployment -> private EKS worker nodes
```

```text
Static site:
app/static/index.html -> private S3 bucket -> CloudFront OAC -> HTTPS viewer
```

The static site and container app are separate demos. If later desired, CloudFront can be extended with another origin and behavior to front an internet-facing ALB; it does not directly connect to a private EKS service. The current EKS demo has no public ingress/load balancer.

## Configure remote state and create the shared network

The state bucket already exists, so there is no bootstrap stack. First confirm in the S3 console that **Block all public access**, **Bucket Versioning**, and default encryption are enabled. Then, in PowerShell, create a local backend config file (ignored by Git) and initialize only the network root:

```powershell
@"
bucket = "devops-user-terraform-state-backend"
region = "ap-south-1"
"@ | Set-Content terraform\backend.hcl
terraform -chdir=terraform\network init -backend-config=..\backend.hcl
terraform -chdir=terraform\network plan
```

The ignored `terraform\backend.hcl` file contains only bucket/region configuration, not credentials. The S3 backend uses native lock files. Ensure your SSO permission set can read/write objects in this bucket and create/delete Terraform lock files. Review the network plan before applying:

```powershell
terraform -chdir=terraform\network apply
terraform -chdir=terraform\network output
```

The network stack creates two public and two private subnets in separate availability zones. The public subnets route through an internet gateway and are for the later ALB. Private subnets have no public IPs and route outbound through one NAT gateway; they are for EKS workers and ASG instances. NAT gateways incur ongoing hourly and data-processing charges. Review the plan before applying and destroy the network last, after destroying EKS and ASG.

The `network` state output is the handoff contract for later stacks. EKS and ASG read its VPC/subnet IDs with `terraform_remote_state`, so they reuse these resources without Terraform trying to manage them a second time. CloudFront uses only S3 and its own distribution; it neither depends on nor attaches to this VPC.

## Deploy the Kubernetes application

1. Apply the EKS stack:

   ```powershell
   terraform -chdir=terraform\eks plan
   terraform -chdir=terraform\eks apply
   ```

   The initial deployment can take several minutes. EKS creates a control plane and two private worker nodes. The role that ran Terraform is granted initial cluster-admin access by EKS.

2. In GitHub, open **Settings → Secrets and variables → Actions → Variables** and add these repository variables from `terraform -chdir=terraform\eks output`:

   | Variable | Terraform output/value |
   | --- | --- |
   | `AWS_ACCOUNT_ID` | `aws_account_id` |
   | `AWS_REGION` | `aws_region` |
   | `ECR_REPOSITORY` | `ecr_repository` |
   | `EKS_CLUSTER_NAME` | `cluster_name` |
   | `AWS_DEPLOY_ROLE_ARN` | `github_deploy_role_arn` |

   These are identifiers, not credentials. `AWS_DEPLOY_ROLE_ARN` is the new repository-scoped role ARN created by Terraform. The EKS stack grants it access only to the `default` namespace. If you change the repository or branch, update `github_repository` or `github_branch` and apply the EKS stack again.

3. Push a commit to `main`. The GitHub Actions workflow runs the unit tests and Docker build; on `main`, it assumes the OIDC role, pushes an immutable commit-tagged image to ECR, and deploys to the `default` namespace. Pull requests run tests and build the image without AWS credentials.

4. Verify locally with your SSO profile:

   ```powershell
   aws eks update-kubeconfig --region (terraform -chdir=terraform\eks output -raw aws_region) --name (terraform -chdir=terraform\eks output -raw cluster_name)
   kubectl get nodes
   kubectl get deployment,service,pods
   ```

The GitHub role can push only to this ECR repository, describe only this EKS cluster, and edit resources only in the `default` namespace. The EKS public API endpoint defaults to allowing connections from any IP because GitHub-hosted runner addresses change; Kubernetes access still requires AWS IAM authentication and the scoped EKS access entry. For a fixed self-hosted runner or VPN, set `cluster_endpoint_public_access_cidrs` to trusted CIDRs and apply again.

## Deploy the CloudFront static site

```powershell
terraform -chdir=terraform\cloudfront plan
terraform -chdir=terraform\cloudfront apply
terraform -chdir=terraform\cloudfront output -raw cloudfront_url
```

Terraform uploads `app/static/index.html` to a private S3 bucket. The bucket has all public access blocked and allows `GetObject` only to the CloudFront distribution through OAC. This uses the private S3 REST origin rather than the S3 website endpoint, so direct bucket URLs are not public. Viewer traffic is redirected to HTTPS.

After changing `app/static/index.html`, run `terraform apply`, then invalidate cached paths:

```powershell
$distribution = terraform -chdir=terraform\cloudfront output -raw cloudfront_distribution_id
aws cloudfront create-invalidation --distribution-id $distribution --paths "/*"
```

The distribution uses a short default cache TTL (5 minutes); invalidations may incur charges beyond the account's free quota.

## Deploy and demonstrate the ALB + Auto Scaling group

```powershell
terraform -chdir=terraform\asg plan
terraform -chdir=terraform\asg apply
terraform -chdir=terraform\asg output -raw alb_url
```

The ALB is public on HTTP port 80. Instances run in private subnets with no SSH ingress; their security group accepts application traffic only from the ALB. The launch template requires IMDSv2 and uses an instance profile for Systems Manager. The target group's `/health` check is also used by the ASG (`health_check_type = "ELB"`), so an unhealthy registered instance is terminated and replaced. A target-tracking policy scales the group toward 70% average CPU utilization.

To observe it:

1. Open the `alb_url` output and check the response. In **EC2 → Target Groups**, inspect the targets and health status.
2. In **Systems Manager → Run Command**, target an instance tagged `Name=it-vedant-app` and stop/disable `demo-app.service`. After the target health checks fail, inspect the ASG's **Activity** history and confirm the unhealthy EC2 instance is replaced. Run Command requires the instance to be registered and online in Systems Manager.
3. To see CPU scaling, use Run Command to generate sustained CPU load on both instances, then watch **EC2 → Auto Scaling Groups → Automatic scaling** and CloudWatch metrics. Scale-out is not instantaneous: target tracking needs sustained load and respects cooldowns. Stop the load afterward. CPU stress can use burst credits on small instance types.

For a production HTTPS endpoint, attach an ACM certificate in the ALB's region and add an HTTPS listener and DNS record; this demo intentionally uses HTTP because no domain/certificate was supplied. The shared VPC module uses one NAT Gateway to reduce lab costs. Production deployments should normally use a NAT Gateway per AZ or suitable VPC endpoints for availability and isolation.

## Tests and Terraform validation

```powershell
python -m unittest discover -s app/tests -v
terraform fmt -check -recursive terraform
```

The `Terraform validation` GitHub Actions workflow validates every root without AWS credentials. The application workflow tests and builds the container on pull requests.

## Cost and cleanup

AWS charges for running resources. EKS has an hourly control-plane charge; the shared NAT Gateway, load balancers, EC2, data transfer, CloudFront requests, and EBS may also incur charges. Do not apply all stacks unless you are comfortable with the ongoing costs. Review the AWS Pricing Calculator for your region and delete demo stacks promptly.

Destroy only the stacks you applied, in their respective directories:

```powershell
terraform -chdir=terraform\cloudfront destroy
terraform -chdir=terraform\asg destroy
terraform -chdir=terraform\eks destroy
terraform -chdir=terraform\network destroy
```

After every stack is destroyed, delete the state bucket last. Because versioning should be enabled, use the S3 console's **Empty** action to remove current objects and all object versions/delete markers, then delete the bucket. Verify the bucket is gone and the VPC, NAT Gateway, EKS, EC2, ALB, and CloudFront resources have been deleted. Charges already incurred can still appear on the bill; monitor Cost Explorer/Billing after cleanup.
