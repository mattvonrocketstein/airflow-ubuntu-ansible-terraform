provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
}

resource "aws_key_pair" "airflow" {
  key_name   = "airflow-key"
  public_key = "${var.pub_key}"
}

resource "aws_instance" "airflow" {
  ami               = "${var.ami}"
  instance_type     = "t2.micro"
  monitoring        = true
  availability_zone = "${var.aws_az}"
  key_name          = "${aws_key_pair.airflow.key_name}"
  tags {
    Name = "airflow${var.deployment_suffix}"
  }
  security_groups = ["${aws_security_group.airflow.name}"]
}


resource "aws_security_group_rule" "main_egress" {
  type            = "egress"
  from_port       = 0
  to_port         = 0
  protocol        = "-1"
  cidr_blocks     = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.airflow.id}"
}

resource "aws_security_group_rule" "ssh" {
  type            = "ingress"
  from_port       = 22
  to_port         = 22
  protocol        = "tcp"
  cidr_blocks     = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.airflow.id}"
}

resource "aws_security_group" "airflow" {
  name = "airflow-sg${var.deployment_suffix}"
  description = "airflow${var.deployment_suffix} security groups"
}

resource "aws_eip" "airflow" {
  instance = "${aws_instance.airflow.id}"
}

output "ip" {
   value = "${aws_eip.airflow.public_ip}"
}
