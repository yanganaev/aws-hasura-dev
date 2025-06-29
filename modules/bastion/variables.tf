variable "allowed_ssh_cidrs" {
  description = "List of CIDR blocks allowed to SSH into Bastion"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "key_name" {
  description = "Name of the EC2 Key Pair"
  type        = string
}