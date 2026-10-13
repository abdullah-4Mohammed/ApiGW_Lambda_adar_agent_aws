# full url to call the api
output "api_url" {
  value = "${aws_api_gateway_stage.api_stage.invoke_url}/${aws_api_gateway_resource.analyse.path_part}"
}

# web page url
output "web_url" {
  value = "https://${aws_cloudfront_distribution.web.domain_name}"
}
