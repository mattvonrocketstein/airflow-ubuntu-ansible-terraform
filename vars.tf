# Top level variables.  Terraform inside modules may require
# these, but module instantiation typically will not override
# them if defaults are provided here.
variable "aws_region" {
  description = "AWS Region for deploying resources into"
  type        = "string"
  default     = "us-east-1"
}

variable "aws_az" {
  description = "default AWS availability zone"
  type        = "string"
  default     = "us-east-1d"
}

variable "deployment_suffix" {
  description = "suffix to apply to names in this deployment (i.e. `-prod`, `-test`, etc)"
  type        = "string"
  default     = ""
}

variable "aws_profile" {
  type        = "string"
  description = "AWS profile to use"
}

variable "pub_key" {
  type        = "string"
  description = "SSH pub key"
}

variable "ami" {
   type        = "string"
   description = "Ubuntu AMI to use.  Must match availability zone, instance type, etc"
   default     = "ami-d45064af"
}
