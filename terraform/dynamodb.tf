# Tabla única (single-table design) para veterinarias y turnos.
# PK/SK definidos para resolver el patrón de acceso principal:
# "turnos de una veterinaria en una fecha" sin Scan ni JOIN.
#
# GSI1 resuelve el patrón secundario: "un turno a partir de su id",
# necesario para GET/PUT/DELETE por turnoId sin conocer vetId ni fecha.
resource "aws_dynamodb_table" "turnos" {
  name         = "${var.project_name}-${var.environment}"
  billing_mode = "PAY_PER_REQUEST" # Cost Optimization: se paga por request, no por capacidad reservada 24/7

  hash_key  = "PK"
  range_key = "SK"

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  attribute {
    name = "GSI1PK"
    type = "S"
  }

  attribute {
    name = "GSI1SK"
    type = "S"
  }

  global_secondary_index {
    name            = "GSI1"
    hash_key        = "GSI1PK"
    range_key       = "GSI1SK"
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = true # Reliability: recuperación ante borrados/escrituras accidentales
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}
