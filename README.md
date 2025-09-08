# Learning Terraform (Refactored for OIDC)

This repo started as a fork of [Learning Terraform][li_course] by [Josh Samuelson][li_instructor].
The original course used IAM users with AdministratorAccess and long-lived access keys.
I refactored the setup to use:

- Terraform Cloud OIDC → IAM Role for workspace runs
- Scoped trust policies per environment (dev, qa)
- Modernized ALB/ASG module wiring (traffic_source_attachments, no target_group_arns)
- Safer defaults (no deletion protection by default, tagged resources, module version pinning)

## Repo structure
- `/dev` – dev environment
- `/qa` – qa environment
- `/modules/blog` – modularized ALB, ASG, VPC, SG

## How this differs from the course
- **Security**: no IAM users or static keys
- **Least privilege**: role trust policies scoped by TFC workspace
- **Modern modules**: fixed drift from v2019 course to v2025 module inputs
- **Multi-env**: dev and qa workspaces run independently in Terraform Cloud

## Developer tooling
I added [pre-commit][precommit] hooks for:

- **Security**: detect-secrets, gitleaks
- **Quality**: Black, Flake8, MyPy (Python modules)
- **Hygiene**: trailing whitespace, YAML checks

Terraform Cloud runs don’t invoke local hooks, but I wanted my fork to model
a secure, professional workflow. The hooks ensure consistent style and prevent
accidental secret commits when working locally.

Read the full write-up on [my blog][medium].

## Original course
You can find the original materials on [GitHub][li_github].

[li_course]: https://www.linkedin.com/learning/learning-terraform-15575129/learn-terraform-for-your-cloud-infrastructure
[li_instructor]: https://www.linkedin.com/in/samuelson/?trk=lil_instructor
[precommit]: https://pre-commit.com/
[li_github]: https://github.com/LinkedInLearning/learning-terraform-3087701
[medium]: https://medium.com/desido/when-tutorials-drift-updating-a-terraform-course-for-todays-aws-5b3f59079007
