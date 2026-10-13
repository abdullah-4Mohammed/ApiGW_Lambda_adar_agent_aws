# full url to call the api
output "api_url" {
  value = "${aws_api_gateway_stage.api_stage.invoke_url}/${aws_api_gateway_resource.analyse.path_part}"
}

# web page url
output "web_url" {
  value = "http://${aws_s3_bucket_website_configuration.web.website_endpoint}"
}
