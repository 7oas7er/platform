output "state_bucket_name" {
  description = "S3 bucket for shared-edge / shared-obs state."
  value       = aws_s3_bucket.state.bucket
}
