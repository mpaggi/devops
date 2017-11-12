# -----------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# -----------------------------------------------------------------------------

variable "ec2tag" {
  description = "Tag Name for EC instance."
  default = "mpaggi-assessment"
}

# HTTP server port
variable "server_port" {
  description = "The port the server will use for HTTP requests"
  default = 8080
}

# public key to access EC2 instance with user ubuntu
variable "public_key_path" {
  description = "The path to the SSH Public Key to add to AWS."
  default = "mpaggi_ec2_key.pub"
}

# private key to access EC2 instance with user ubuntu
variable "private_key_path" {
  description = "The path to the SSH Private Key to run provisioner."
  default = "mpaggi_ec2_key"
}

variable "hostname" {
  description = "Hostname for EC2 instance."
  default = "mpaggi-dokku"
}

variable "envjs" {
  description = "Set env variable on EC2 instance."
  default = "development"
}
