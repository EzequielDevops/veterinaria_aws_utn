# HTTP API (no REST API): más simple y más barato, consistente con el
# pilar de Cost Optimization que usamos como hilo conductor en la charla.

resource "aws_apigatewayv2_api" "turnos_api" {
  name          = "${var.project_name}-api-${var.environment}"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.turnos_api.id
  name        = "$default"
  auto_deploy = true
}

# --- Integraciones: una por función Lambda ---

resource "aws_apigatewayv2_integration" "create_turno" {
  api_id                 = aws_apigatewayv2_api.turnos_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.create_turno.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "get_turno" {
  api_id                 = aws_apigatewayv2_api.turnos_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.get_turno.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "list_turnos" {
  api_id                 = aws_apigatewayv2_api.turnos_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.list_turnos.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "update_turno" {
  api_id                 = aws_apigatewayv2_api.turnos_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.update_turno.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "delete_turno" {
  api_id                 = aws_apigatewayv2_api.turnos_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.delete_turno.invoke_arn
  payload_format_version = "2.0"
}

# --- Rutas: mapeo explícito verbo HTTP + path -> función (el CRUD) ---

resource "aws_apigatewayv2_route" "create_turno" {
  api_id    = aws_apigatewayv2_api.turnos_api.id
  route_key = "POST /turnos"
  target    = "integrations/${aws_apigatewayv2_integration.create_turno.id}"
}

resource "aws_apigatewayv2_route" "get_turno" {
  api_id    = aws_apigatewayv2_api.turnos_api.id
  route_key = "GET /turnos/{turnoId}"
  target    = "integrations/${aws_apigatewayv2_integration.get_turno.id}"
}

resource "aws_apigatewayv2_route" "list_turnos" {
  api_id    = aws_apigatewayv2_api.turnos_api.id
  route_key = "GET /turnos"
  target    = "integrations/${aws_apigatewayv2_integration.list_turnos.id}"
}

resource "aws_apigatewayv2_route" "update_turno" {
  api_id    = aws_apigatewayv2_api.turnos_api.id
  route_key = "PUT /turnos/{turnoId}"
  target    = "integrations/${aws_apigatewayv2_integration.update_turno.id}"
}

resource "aws_apigatewayv2_route" "delete_turno" {
  api_id    = aws_apigatewayv2_api.turnos_api.id
  route_key = "DELETE /turnos/{turnoId}"
  target    = "integrations/${aws_apigatewayv2_integration.delete_turno.id}"
}

# --- Permisos: API Gateway invocando cada Lambda ---

resource "aws_lambda_permission" "create_turno" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_turno.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.turnos_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "get_turno" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_turno.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.turnos_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "list_turnos" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.list_turnos.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.turnos_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "update_turno" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.update_turno.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.turnos_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "delete_turno" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.delete_turno.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.turnos_api.execution_arn}/*/*"
}
