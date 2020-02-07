# ---------------------------------------------------------------------------------------------------------------------
# ENVIRONMENT VARIABLES
# Define these secrets as environment variables
# ---------------------------------------------------------------------------------------------------------------------

# AWS_ACCESS_KEY_ID
# AWS_SECRET_ACCESS_KEY
# AWS_DEFAULT_REGION

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

variable "gateway_region" {
  type    = string
  default = "eu-west-2"
}

variable "ami_id_server" {
  description = "The ID of the AMId"
  type        = string
  default     = ""
}

variable "ssh_key_name" {
  description = "The name of an EC2 Key Pair that can be used to SSH to the EC2 Instances in this cluster. Set to an empty string to not associate a Key Pair."
  type        = string
  default     = ""
}

variable "subnet_id" {
  type    = string
  default = ""
}

variable "allowed_inbound_cidr_blocks" {
  type    = list
  default = ["0.0.0.0/0"]
}

variable "vpc_id" {
  description = "The ID of the VPC in which the nodes will be deployed.  Uses default VPC if not supplied."
  type        = string
  default     = ""
}

variable "container_name" {
  description = "docker container name"
  type        = string
  default     = ""
}

variable "docker_repo" {
  description = "Docker repo to pull the solution docker images from"
  type        = string
  default     = ""
}

variable "docker_repo_user" {
  description = "The user name to access the docker repo defined by docker_repo"
  type        = string
  default     = "docker-readonly"
}

variable "docker_repo_password" {
  description = "The password to access the docker repo defined by docker_repo for the docker_repo_user"
  type        = string
  default     = "dummy_not_used"
}

variable "enable_elb" {
  type    = bool
  default = true
}

variable "elb_name" {
  type    = string
  default = "GPRecordsProxyALB"
}

variable "elb_access_logs_prefix" {
  type    = string
  default = "GPRecordsProxyALB"
}

variable "elb_target_group_name" {
  type    = string
  default = "GPRecordsProxyALB"
}

variable "elb_certificate_arn" {
  type    = string
  default = ""
}

variable "public_elb_subnet_ids" {
  description = "The subnet IDs (public) for ALB"
  type        = list(string)
  default     = []
}

variable "private_subnet_names" {
  type    = list
  default = []
}

variable "gprecords_elb_sg_name" {
  description = "Name of the security group for the gateway ELB"
  type        = string
  default     = "GPRecordsProxy-elb-dev-sg"
}

variable "gprecords_elb_whitelist_cidr" {
  description = "A list of CIDR-formatted IP address ranges from which Proxy API clients will allow connections to the gateway via ELB"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "https_port" {
  description = "The port used to resolve ELB queries."
  type        = number
  default     = 443
}

variable "gateway_http_port" {
  description = "The port used to resolve ELB queries."
  type        = number
  default     = 8080
}

variable "alb_listener_port" {
  description = "The port for deapi elb"
  default     = 443
}

variable "alb_listener_protocol" {
  description = "The protocol for deapi elb"
  default     = "HTTPS"
}

variable "gateway_route53_record_alias" {
  description = "The alias under which a Route53 target group will be created"
  type        = string
  default     = "gprecords-proxy-gateway"
}

variable "target_domain_hosted_zone_id" {
  description = "The hosted zone id for the domain under which the alias for the target elb will be created"
  type        = string
  default     = ""
}

variable "alias_target_elb_hosted_zone_id" {
  description = "The hostez zone id for the elb that targets alias"
  type        = string
  default     = ""
}

variable "elb_listener_security_policy" {
  type    = string
  default = "ELBSecurityPolicy-TLS-1-2-2017-01"
}
