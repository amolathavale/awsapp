provider "aws" {
  profile    = "default"
  region     = "us-east-1"
}

resource "aws_s3_bucket" "module1" {
    bucket = "amol.digitek"
    acl = "public-read"
    policy = "${file("aws-cli/website-bucket-policy.json")}"
    website {
        index_document = "index.html"
        error_document = "error.html"
    }
    provisioner "local-exec" {
     command = "aws s3 sync ${path.module}/web s3://${aws_s3_bucket.module1.bucket}"
  }
}
