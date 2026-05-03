# Challenges and Resolutions

## Challenge 1 — Restricted EC2 IAM Permissions
**Problem:** Initial environment was a restricted EC2 instance with WeekendRole
that had no EC2 or RDS permissions. terraform plan failed immediately.
**Resolution:** Attached required AWS managed policies via IAM console.

## Challenge 2 — RDS Identifier Starting with Number
**Problem:** project_name "8byte-devops" starts with "8".
RDS identifier must start with a letter.
**Resolution:** Renamed to "eightbyte-devops" in variables.tf.

## Challenge 3 — AZ Fetch Permission Denied
**Problem:** ec2:DescribeAvailabilityZones not allowed by WeekendRole.
**Resolution:** Hardcoded ap-south-1a and ap-south-1b using locals block,
removing the API call entirely.

## Challenge 4 — PostgreSQL Version Not Available
**Problem:** engine_version "15.4" not available in ap-south-1 region.
**Resolution:** Ran aws rds describe-db-engine-versions to list available
versions and updated to 16.6.

## Challenge 5 — Jenkins Sudo Permissions
**Problem:** Jenkins user has no sudo access, tidy installation
failed in pipeline.
**Resolution:** Pre-installed tidy on EC2 instance and removed
runtime installation from pipeline.

## Challenge 6 — AWS Credential Management
**Problem:** Creating IAM access keys is a security anti-pattern.
**Resolution:** Used EC2 IAM instance role for Jenkins AWS authentication.
Removed withAWS credential block, Jenkins uses credential provider
chain automatically.

## Challenge 7 — withAWS Credential Conflict
**Problem:** withAWS block looking for stored Jenkins credentials
but EC2 IAM role does not need them.
**Resolution:** Removed withAWS wrapper entirely. Jenkins uses EC2
IAM role automatically via AWS credential provider chain.

## Challenge 8 — RDS Enhanced Monitoring IAM Permission
**Problem:** iam:PassRole permission not available on WeekendRole.
Could not enable RDS Enhanced Monitoring.
**Resolution:** Used default CloudWatch RDS metrics (AWS/RDS namespace)
which provide sufficient database monitoring without requiring
Enhanced Monitoring role.

## Challenge 9 — CloudWatch Dashboard Validation Errors
**Problem:** put-dashboard failed with 15 validation errors
due to missing region and annotations fields.
**Resolution:** Added region and annotations fields to each widget,
saved dashboard JSON to file and used file:// reference
instead of inline JSON.
