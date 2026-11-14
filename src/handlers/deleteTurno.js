'use strict';

const { QueryCommand, DeleteCommand } = require('@aws-sdk/lib-dynamodb');
const { docClient, TABLE_NAME, response } = require('../lib/dynamo');

/**
 * DELETE — DELETE /turnos/{turnoId}
 *
 * Mapeo CRUD -> DynamoDB: Delete -> DeleteItem
 *
 * Mismo patrón que update: resolver PK+SK vía GSI1 antes de poder borrar,
 * porque DeleteItem en DynamoDB requiere la clave primaria completa.
 */
exports.handler = async (event) => {
  const { turnoId } = event.pathParameters || {};

  if (!turnoId) {
    return response(400, { message: 'Falta turnoId en el path' });
  }

  const found = await docClient.send(
    new QueryCommand({
      TableName: TABLE_NAME,
      IndexName: 'GSI1',
      KeyConditionExpression: 'GSI1PK = :turnoId',
      ExpressionAttributeValues: { ':turnoId': turnoId },
    })
  );

  if (!found.Items || found.Items.length === 0) {
    return response(404, { message: 'Turno no encontrado' });
  }

  const { PK, SK } = found.Items[0];

  await docClient.send(
    new DeleteCommand({
      TableName: TABLE_NAME,
      Key: { PK, SK },
    })
  );

  return response(204, null);
};
