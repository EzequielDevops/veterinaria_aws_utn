output "api_base_url" {
  description = "URL base de la API para probar el CRUD con curl"
  value       = aws_apigatewayv2_stage.default.invoke_url
}

output "dynamodb_table_name" {
  description = "Nombre de la tabla DynamoDB creada"
  value       = aws_dynamodb_table.turnos.name
}
