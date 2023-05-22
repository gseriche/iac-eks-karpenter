variable "capacity_type" {
  description = "What types of nodes to spawn. Can be spot/on-demand, or both"
  type        = list(any)
  default     = ["spot", "on-demand"]
}

variable "allowed_instance_types" {
  description = "Which instance types Karpenter is allowed to spin up"
  type        = list(any)
  default = [
    "t3.medium",
    "t3a.medium",
    "t3.large",
    "t3a.large",
    "t3.2xlarge",
    "t3a.2xlarge",
    "m5.large",
    "m5a.large",
    "m5.2xlarge",
    "m5a.2xlarge",
    "m5.4xlarge",
    "m5a.4xlarge",
    "m5.8xlarge",
    "m5a.8xlarge",
    "c5.large",
    "c5a.large",
    "c5.2xlarge",
    "c5a.2xlarge",
    "c5.4xlarge",
    "c5a.4xlarge",
    "c5.9xlarge",
    "c5a.9xlarge",
    "c5d.12xlarge",
    "c5d.18xlarge",
    "c5d.24xlarge",
    "c5a.24xlarge",
    "c5.24xlarge"
  ]
}

variable "max_cpus_allowed" {
  description = "How many CPU cores will be allowed in the cluster"
  type        = string
  default     = "1000"
}

variable "instance_time_to_live" {
  description = "How long an individual instance will live for until the node is tainted"
  type        = number
  default     = 3600
}

variable "bucket_backend_name" {
  description = "Name of the backend bucket to be created"
  type        = string

}
