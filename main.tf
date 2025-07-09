provider "aws" {
  region = "ap-south-1"
}

# ------------------------------
# S3 Bucket + Folders
# ------------------------------
resource "aws_s3_bucket" "lambda_bucket" {
  bucket        = var.bucket_name
  force_destroy = true
}

resource "aws_s3_object" "input_folder" {
  bucket  = aws_s3_bucket.lambda_bucket.id
  key     = "input_files/"
  content = ""
}

resource "aws_s3_object" "output_folder" {
  bucket  = aws_s3_bucket.lambda_bucket.id
  key     = "output_files/"
  content = ""
}

# ------------------------------
# IAM Role for Lambda
# ------------------------------
resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_python_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

# Inline policy: S3 access + logging
resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda_s3_access_policy"
  role = aws_iam_role.lambda_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ],
        Resource = "${aws_s3_bucket.lambda_bucket.arn}/*"
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      }
    ]
  })
}

# Attach AWS managed policy: AmazonS3FullAccess
resource "aws_iam_role_policy_attachment" "lambda_s3_full_access" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# ------------------------------
# Lambda Function
# ------------------------------
resource "aws_lambda_function" "lambda_function" {
  function_name    = var.lambda_function_name
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  role             = aws_iam_role.lambda_exec_role.arn
  filename         = "lambda.zip"
  source_code_hash = filebase64sha256("lambda.zip")

  depends_on = [
    aws_iam_role_policy.lambda_policy,
    aws_iam_role_policy_attachment.lambda_s3_full_access
  ]
}

# ------------------------------
# S3 Trigger for Lambda
# ------------------------------
resource "aws_lambda_permission" "s3_trigger_permission" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.lambda_bucket.arn
}

resource "aws_s3_bucket_notification" "s3_trigger" {
  bucket = aws_s3_bucket.lambda_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.lambda_function.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "input_files/"
  }

  depends_on = [aws_lambda_permission.s3_trigger_permission]
}
