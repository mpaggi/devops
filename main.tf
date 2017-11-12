# DEPLOY A SINGLE EC2 INSTANCE

# ------------------------------------------------------------------------------
# CONFIGURE OUR AWS CONNECTION
# ------------------------------------------------------------------------------

provider "aws" {
  region = "eu-central-1"
}

resource "aws_instance" "mpaggi" {
  # Ubuntu Server 16.04 LTS (HVM) SSD
  ami = "ami-97e953f8"
  # Ubuntu Server 14.04 LTS (HVM) SSD
  #ami = "ami-dc0287b3"
  instance_type = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.instance.id}"]

  user_data = <<-EOF
#!/bin/bash
set -e # Exit on errors
sudo cp -p /root/.ssh/authorized_keys{,.bck}
sudo cat /root/.ssh/authorized_keys | sed 's/^.*ssh-rsa/ssh-rsa/' > /tmp/key.temp && sudo mv -f /tmp/key.temp /root/.ssh/authorized_keys
cd /tmp/
wget https://raw.githubusercontent.com/dokku/dokku/v0.10.5/bootstrap.sh
sudo DOKKU_TAG="v0.10.5" DOKKU_VHOST_ENABLE="true" DOKKU_WEB_CONFIG="false" DOKKU_HOSTNAME="${var.hostname}" DOKKU_SKIP_KEY_FILE="true" DOKKU_KEY_FILE="/home/ubuntu/.ssh/authorized_keys" bash bootstrap.sh
dokku apps:create sample-node-app
echo "127.0.0.1	sample-node-app.${var.hostname}" >> /etc/hosts
echo "env=${var.envjs}" >> /etc/environment 
touch /home/ubuntu/cloud-init-complete
		EOF
  tags {
    Name = "${var.ec2tag}"
  }

  key_name = "rvg-mpaggi"
}

# ------------------------------------------------------------------------------
# KEY PAIR 

resource "aws_key_pair" "mpaggi" {
  key_name = "rvg-mpaggi"
  public_key = "${file(var.public_key_path)}"
}

# ------------------------------------------------------------------------------
# IP ADDRESS
# ------------------------------------------------------------------------------
resource "aws_eip" "mpaggi_eip" {
  instance = "${aws_instance.mpaggi.id}"
  vpc      = true
}

# ------------------------------------------------------------------------------
# CREATE THE SECURITY GROUP FOR THE EC2 INSTANCE
# ------------------------------------------------------------------------------

resource "aws_security_group" "instance" {
  name = "mpaggi-assessment-sg"

  # Inbound HTTP from anywhere
  ingress {
    from_port = "${var.server_port}"
    to_port = "${var.server_port}"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ssh connection (testing purpose)
  ingress {
    from_port = "22"
    to_port = "22"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # http incoming
  ingress {
    from_port = "80"
    to_port = "80"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS outgoing (dokku install, apt, etc...)
  egress {
    from_port = "443"
    to_port = "443"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP outgoing (apt, updates, etc...)
  egress {
    from_port = "80"
    to_port = "80"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
