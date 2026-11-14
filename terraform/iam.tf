# Un rol por función Lambda, con permisos acotados exclusivamente a la
# acción de DynamoDB que esa función necesita (Security: mínimo privilegio).
# Nada de "AmazonDynamoDBFullAccess" compartido entre todas las funciones.

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# --- createTurno: solo PutItem ---
resource "aws_iam_role" "create_turno" {
  name               = "${var.project_name}-create-turno-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy" "create_turno" {
  name = "dynamo-put-item"
  role = aws_iam_role.create_turno.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["dynamodb:PutItem"]
      Resource = aws_dynamodb_table.turnos.arn
    }]
  })
}

# --- getTurno: solo Query (incluye el índice GSI1) ---
resource "aws_iam_role" "get_turno" {
  name               = "${var.project_name}-get-turno-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy" "get_turno" {
  name = "dynamo-query"
  role = aws_iam_role.get_turno.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["dynamodb:Query"]
      Resource = [
        aws_dynamodb_table.turnos.arn,
        "${aws_dynamodb_table.turnos.arn}/index/*"
      ]
    }]
  })
}

# --- listTurnos: solo Query sobre la tabla base ---
resource "aws_iam_role" "list_turnos" {
  name               = "${var.project_name}-list-turnos-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy" "list_turnos" {
  name = "dynamo-query"
  role = aws_iam_role.list_turnos.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["dynamodb:Query"]
      Resource = aws_dynamodb_table.turnos.arn
    }]
  })
}

# --- updateTurno: Query (para resolver PK/SK) + UpdateItem ---
resource "aws_iam_role" "update_turno" {
  name               = "${var.project_name}-update-turno-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy" "update_turno" {
  name = "dynamo-query-update"
  role = aws_iam_role.update_turno.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["dynamodb:Query"]
        Resource = [
          aws_dynamodb_table.turnos.arn,
          "${aws_dynamodb_table.turnos.arn}/index/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["dynamodb:UpdateItem"]
        Resource = aws_dynamodb_table.turnos.arn
      }
    ]
  })
}

# --- deleteTurno: Query (para resolver PK/SK) + DeleteItem ---
resource "aws_iam_role" "delete_turno" {
  name               = "${var.project_name}-delete-turno-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy" "delete_turno" {
  name = "dynamo-query-delete"
  role = aws_iam_role.delete_turno.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["dynamodb:Query"]
        Resource = [
          aws_dynamodb_table.turnos.arn,
          "${aws_dynamodb_table.turnos.arn}/index/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["dynamodb:DeleteItem"]
        Resource = aws_dynamodb_table.turnos.arn
      }
    ]
  })
}

# --- Logs: todas las funciones necesitan escribir en CloudWatch Logs ---
resource "aws_iam_role_policy_attachment" "logs" {
  for_each = {
    create_turno = aws_iam_role.create_turno.name
    get_turno    = aws_iam_role.get_turno.name
    list_turnos  = aws_iam_role.list_turnos.name
    update_turno = aws_iam_role.update_turno.name
    delete_turno = aws_iam_role.delete_turno.name
  }

  role       = each.value
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
