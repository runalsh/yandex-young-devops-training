#========== S3 ======================================================================================

resource "aws_s3_bucket" "lblogs" {
  bucket        = "logsfromelb"
  force_destroy = true
}

resource "aws_s3_bucket" "terraform_state" {
   bucket = "statebucket-for-s3"
   lifecycle {
     prevent_destroy = true
   }
 } 