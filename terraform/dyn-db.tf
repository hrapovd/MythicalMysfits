variable "dydb_data" {
  type    = string
  default = "../aws-modern-application-workshop/module-3/aws-cli/populate-dynamodb.json"
}

resource "aws_dynamodb_table" "dyn_db1" {
  name           = "MysfitsTable"
  hash_key       = "MysfitId"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  attribute {
    name = "MysfitId"
    type = "S"
  }
  attribute {
    name = "GoodEvil"
    type = "S"
  }
  attribute {
    name = "LawChaos"
    type = "S"
  }
  global_secondary_index {
    name            = "LawChaosIndex"
    hash_key        = "LawChaos"
    range_key       = "MysfitId"
    projection_type = "ALL"
    read_capacity   = 5
    write_capacity  = 5
  }
  global_secondary_index {
    name            = "GoodEvilIndex"
    hash_key        = "GoodEvil"
    range_key       = "MysfitId"
    projection_type = "ALL"
    read_capacity   = 5
    write_capacity  = 5
  }
}

resource "aws_dynamodb_table_item" "dyn_db1_items" {
  for_each   = jsondecode(file("${path.module}/${var.dydb_data}"))
  table_name = aws_dynamodb_table.dyn_db1.name
  hash_key   = aws_dynamodb_table.dyn_db1.hash_key
  item       = jsonencode(each.value)
}