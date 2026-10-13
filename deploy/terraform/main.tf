data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../../src/lambda/lambda.py"
  output_path = "${path.module}/../../src/lambda/lambda.zip"
}

# lambda function (python) as the backend for the api gateway
resource "aws_lambda_function" "lam" {
  function_name = "${local.resourceName}-lam"
  handler = "lambda.handler"
  runtime = "python3.12"
  role = aws_iam_role.role.arn
  filename = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
}

# add api gateway
resource "aws_api_gateway_rest_api" "api" {
  name = "${local.resourceName}-api-gw"
}

# path: /analyse
resource "aws_api_gateway_resource" "analyse" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id = aws_api_gateway_rest_api.api.root_resource_id
  path_part = "analyse"
}

# POST because the text is sent in the request body
resource "aws_api_gateway_method" "api_method" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.analyse.id
  http_method = "POST"
  authorization = "NONE"
}

#  this code block creates a new API Gateway integration that responds to
#   the specified HTTP method on the specified resource, calls the specified 
#   Lambda function when invoked, and uses a Lambda proxy integration.
#   (lambda is always invoked with POST, whatever the client method is)

resource "aws_api_gateway_integration" "api_integration" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.analyse.id
  http_method = aws_api_gateway_method.api_method.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = aws_lambda_function.lam.invoke_arn
}

resource "aws_api_gateway_deployment" "api_deployment" {
  depends_on = [aws_api_gateway_integration.api_integration]
  rest_api_id = aws_api_gateway_rest_api.api.id

  # redeploy the api when its routes change
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.analyse.id,
      aws_api_gateway_method.api_method.id,
      aws_api_gateway_integration.api_integration.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "api_stage" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name = "dev"
  deployment_id = aws_api_gateway_deployment.api_deployment.id
}

resource "aws_lambda_permission" "api_lambda_permission" {
  statement_id = "AllowAPIGatewayInvoke"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lam.function_name
  principal = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}



# Create the IAM role
resource "aws_iam_role" "role" {
  name = "${local.resourceName}-role"
  assume_role_policy = <<EOT
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "lambda.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOT
}

# Create the policy (lambda only needs to write its logs)
resource "aws_iam_policy" "policy" {
  name        = "${local.resourceName}-policy"
  description = "Policy for Lambda CloudWatch Logs"

  policy = <<EOT
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    }
  ]
}
EOT
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "policy-attachment" {
  role = aws_iam_role.role.name
  policy_arn = aws_iam_policy.policy.arn
}
