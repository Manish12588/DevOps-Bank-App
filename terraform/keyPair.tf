resource "aws_key_pair" "my_key_pair" {
  key_name   = "devops-bank-app-key"
  public_key = file("${path.module}/devops-bank-app-key.pub")
}
