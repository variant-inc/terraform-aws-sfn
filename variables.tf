variable "name" {
  description = "Name of the state machine."
  type        = string
}

variable "tags" {
  type        = map(string)
  description = "Tags for S3 bucket"
  default     = {}
}

variable "create_role" {
  description = "Specifies should role be created with module or will there be external one provided."
  type        = bool
  default     = true
}

variable "role" {
  description = "Custom role ARN used for SFN state machine."
  type        = string
  default     = ""
}

variable "type" {
  description = "Sets type of the State Machine."
  type        = string
  default     = "STANDARD"
}

variable "definition_filename" {
  description = "Filename of the definition that will be used."
  type        = string
  default     = "state-machine.json"
}

variable "definition_variables" {
  description = "Map of variables and values used in definition templatefile."
  type        = map(any)
  default     = {}
}

variable "logging_configuration" {
  description = "Contains all of the configuration for logging."
  type        = any
  default     = {}
}

variable "enable_tracing" {
  description = "Enables AWS X-Ray tracing."
  type        = bool
  default     = false
}