variable "ami_ids" {
  default     = "ami-07355fe79b493752d"
  description = "ami id for the ec2 instance"
  type        = string
}

variable "instance_type" {
  default     = "t3.medium"
  description = "instance-class-for-the-ec2 machine"
  type        = string
}
