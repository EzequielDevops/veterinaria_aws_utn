'use strict';

const { QueryCommand } = require('@aws-sdk/lib-dynamodb');
const { docClient, TABLE_NAME, response } = require('../lib/dynamo');

/**
 * READ (uno) — GET /turnos/{turnoId}
 *
 * Mapeo CRUD -> DynamoDB: Read por id -> Query sobre GSI1
 *
 * No conocemos vetId ni fecha a partir del turnoId solo, así que no
 * podemos hacer GetItem directo sobre la tabla base (que requiere PK+SK).
 * Por eso existe GSI1: un índice secundario donde GSI1PK = turnoId,
 * permite resolver "dame el turno con este id" en una sola operación
 * indexada, sin escanear toda la tabla (Scan sería O(n) y carísimo).
 */
exports.handler = async (event) => {
  const { turnoId } = event.pathParameters || {};

  if (!turnoId) {
    return response(400, { message: 'Falta turnoId en el path' });
  }

  const result = await docClient.send(
    new QueryCommand({
      TableName: TABLE_NAME,
      IndexName: 'GSI1',
      KeyConditionExpression: 'GSI1PK = :turnoId',
      ExpressionAttributeValues: { ':turnoId': turnoId },
    })
  );

  if (!result.Items || result.Items.length === 0) {
    return response(404, { message: 'Turno no encontrado' });
  }

  return response(200, result.Items[0]);
};
