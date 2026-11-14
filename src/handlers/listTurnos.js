'use strict';

const { QueryCommand } = require('@aws-sdk/lib-dynamodb');
const { docClient, TABLE_NAME, response } = require('../lib/dynamo');

/**
 * READ (listado) — GET /turnos?vetId=...&fecha=...
 *
 * Mapeo CRUD -> DynamoDB: Read por rango -> Query con begins_with
 *
 * Este es el patrón de acceso principal del caso: "todos los turnos de
 * una veterinaria en un día". No existe un SELECT * ni un WHERE libre:
 * el acceso se resuelve porque el SK se diseñó como
 * TURNO#<fecha>#<hora>#<turnoId>, lo que permite filtrar por prefijo
 * (begins_with) de forma eficiente, sin tocar registros de otros días
 * ni de otras veterinarias.
 */
exports.handler = async (event) => {
  const { vetId, fecha } = event.queryStringParameters || {};

  if (!vetId) {
    return response(400, { message: 'Falta query param vetId' });
  }

  const skPrefix = fecha ? `TURNO#${fecha}` : 'TURNO#';

  const result = await docClient.send(
    new QueryCommand({
      TableName: TABLE_NAME,
      KeyConditionExpression: 'PK = :pk AND begins_with(SK, :skPrefix)',
      ExpressionAttributeValues: {
        ':pk': `VET#${vetId}`,
        ':skPrefix': skPrefix,
      },
    })
  );

  return response(200, { turnos: result.Items || [] });
};
