output "lambda_function_name" {
  value = aws_lambda_function.lambda_function.function_name
}

output "bucket_name" {
  value = aws_s3_bucket.lambda_bucket.id
}
