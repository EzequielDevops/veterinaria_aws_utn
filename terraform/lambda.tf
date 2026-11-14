# Una función Lambda por operación CRUD. El empaquetado se hace 100% con
# Terraform (data "archive_file"), sin scripts de shell ni "npm run build"
# por fuera: el .zip se genera en memoria/en dist/ al correr plan/apply y
# se re-crea solo si el código fuente cambia (source_code_hash).
#
# Los handlers solo usan el SDK de AWS (@aws-sdk/*), que viene preinstalado
# en el runtime nodejs20.x de Lambda -- por eso no hace falta empaquetar
# node_modules. createTurno usa crypto.randomUUID() (nativo de Node) en vez
# de una dependencia npm, para no necesitar node_modules en ningún handler.

locals {
  dist_dir = "${path.module}/../dist"
}

data "archive_file" "create_turno" {
  type        = "zip"
  output_path = "${local.dist_dir}/createTurno.zip"

  source {
    content  = file("${path.module}/../src/handlers/createTurno.js")
    filename = "src/handlers/createTurno.js"
  }
  source {
    content  = file("${path.module}/../src/lib/dynamo.js")
    filename = "src/lib/dynamo.js"
  }
}

data "archive_file" "get_turno" {
  type        = "zip"
  output_path = "${local.dist_dir}/getTurno.zip"

  source {
    content  = file("${path.module}/../src/handlers/getTurno.js")
    filename = "src/handlers/getTurno.js"
  }
  source {
    content  = file("${path.module}/../src/lib/dynamo.js")
    filename = "src/lib/dynamo.js"
  }
}

data "archive_file" "list_turnos" {
  type        = "zip"
  output_path = "${local.dist_dir}/listTurnos.zip"

  source {
    content  = file("${path.module}/../src/handlers/listTurnos.js")
    filename = "src/handlers/listTurnos.js"
  }
  source {
    content  = file("${path.module}/../src/lib/dynamo.js")
    filename = "src/lib/dynamo.js"
  }
}

data "archive_file" "update_turno" {
  type        = "zip"
  output_path = "${local.dist_dir}/updateTurno.zip"

  source {
    content  = file("${path.module}/../src/handlers/updateTurno.js")
    filename = "src/handlers/updateTurno.js"
  }
  source {
    content  = file("${path.module}/../src/lib/dynamo.js")
    filename = "src/lib/dynamo.js"
  }
}

data "archive_file" "delete_turno" {
  type        = "zip"
  output_path = "${local.dist_dir}/deleteTurno.zip"

  source {
    content  = file("${path.module}/../src/handlers/deleteTurno.js")
    filename = "src/handlers/deleteTurno.js"
  }
  source {
    content  = file("${path.module}/../src/lib/dynamo.js")
    filename = "src/lib/dynamo.js"
  }
}

resource "aws_lambda_function" "create_turno" {
  function_name = "${var.project_name}-create-turno-${var.environment}"
  role          = aws_iam_role.create_turno.arn
  handler       = "src/handlers/createTurno.handler"
  runtime       = "nodejs20.x"
  timeout       = 5
  memory_size   = 128

  filename         = data.archive_file.create_turno.output_path
  source_code_hash = data.archive_file.create_turno.output_base64sha256

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.turnos.name
    }
  }
}

resource "aws_lambda_function" "get_turno" {
  function_name = "${var.project_name}-get-turno-${var.environment}"
  role          = aws_iam_role.get_turno.arn
  handler       = "src/handlers/getTurno.handler"
  runtime       = "nodejs20.x"
  timeout       = 5
  memory_size   = 128

  filename         = data.archive_file.get_turno.output_path
  source_code_hash = data.archive_file.get_turno.output_base64sha256

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.turnos.name
    }
  }
}

resource "aws_lambda_function" "list_turnos" {
  function_name = "${var.project_name}-list-turnos-${var.environment}"
  role          = aws_iam_role.list_turnos.arn
  handler       = "src/handlers/listTurnos.handler"
  runtime       = "nodejs20.x"
  timeout       = 5
  memory_size   = 128

  filename         = data.archive_file.list_turnos.output_path
  source_code_hash = data.archive_file.list_turnos.output_base64sha256

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.turnos.name
    }
  }
}

resource "aws_lambda_function" "update_turno" {
  function_name = "${var.project_name}-update-turno-${var.environment}"
  role          = aws_iam_role.update_turno.arn
  handler       = "src/handlers/updateTurno.handler"
  runtime       = "nodejs20.x"
  timeout       = 5
  memory_size   = 128

  filename         = data.archive_file.update_turno.output_path
  source_code_hash = data.archive_file.update_turno.output_base64sha256

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.turnos.name
    }
  }
}

resource "aws_lambda_function" "delete_turno" {
  function_name = "${var.project_name}-delete-turno-${var.environment}"
  role          = aws_iam_role.delete_turno.arn
  handler       = "src/handlers/deleteTurno.handler"
  runtime       = "nodejs20.x"
  timeout       = 5
  memory_size   = 128

  filename         = data.archive_file.delete_turno.output_path
  source_code_hash = data.archive_file.delete_turno.output_base64sha256

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.turnos.name
    }
  }
}
