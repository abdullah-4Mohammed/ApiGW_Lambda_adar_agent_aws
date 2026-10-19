# ApiGW_Lambda_adar_agent_aws

A serverless text analyser API on AWS. Send it text and it returns the character, word and sentence counts, the most frequent words and an estimated reading time.

## Components
- **Web:** static web page on Amazon S3 (private) served by CloudFront
- **API:** Amazon API Gateway (REST), `POST /analyse`
- **Logic:** AWS Lambda (Python)

## Built with
- Terraform (AWS: S3, CloudFront, API Gateway, Lambda, IAM)
- Azure DevOps Pipelines (CI/CD)

## License
See [LICENSE.md](LICENSE.md).
