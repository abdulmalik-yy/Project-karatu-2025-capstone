variable "table_name" {
  description = "The name of the DynamoDB table"
  type        = string
  default     = "project-bedrock-table"
}

variable "hash_key" {
  description = "Primary (hash) key attribute name"
  type        = string
  default     = "id"
}

variable "billing_mode" {
  description = "Billing mode for the table (PROVISIONED or PAY_PER_REQUEST)"
  type        = string
  default     = "PROVISIONED"
}

variable "read_capacity" {
  description = "Read capacity units (if PROVISIONED)"
  type        = number
  default     = 5
}

variable "write_capacity" {
  description = "DynamoDB write capacity"
  type        = number
  default     = 0
}

variable "gsi_name" {
  description = "Global Secondary Index Name"
  type        = string
  default     = ""
}

variable "gsi_hash_key" {
  description = "Global Secondary Index Hash Key"
  type        = string
  default     = ""
}
