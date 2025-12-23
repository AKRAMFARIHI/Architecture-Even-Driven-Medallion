
# Bucket bronze
resource "aws_s3_bucket" "bucket_bronze" {
    bucket = "evaluation-bucket-bronze"
}

# Bucker silver
resource "aws_s3_bucket" "bucket_silver" {
    bucket = "evaluation-bucket-silver"
}

# Bucker gold 
resource "aws_s3_bucket" "bucket_gold" {
    bucket = "evaluation-bucket-gold"
}