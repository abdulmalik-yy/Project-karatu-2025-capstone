# DynamoDB module

resource "aws_dynamodb_table" "table" {
  name           = var.table_name
  hash_key       = var.hash_key
  billing_mode   = var.billing_mode
  read_capacity  = var.read_capacity
  write_capacity = var.write_capacity

  attribute {
    name = var.hash_key
    type = "S"
  }

  dynamic "attribute" {
    for_each = var.gsi_hash_key != "" ? [1] : []
    content {
      name = var.gsi_hash_key
      type = "S"
    }
  }

  dynamic "global_secondary_index" {
    for_each = var.gsi_name != "" ? [1] : []
    content {
      name               = var.gsi_name
      hash_key           = var.gsi_hash_key
      projection_type    = "ALL"
    }
  }

  tags = {
    Name    = var.table_name
    project = "karatu-2025-capstone"
  }
}
