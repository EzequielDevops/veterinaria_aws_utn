'use strict';

const { QueryCommand, UpdateCommand } = require('@aws-sdk/lib-dynamodb');
const { docClient, TABLE_NAME, response } = require('../lib/dynamo');

/**
 * UPDATE — PUT /turnos/{turnoId}
 *
 * Mapeo CRUD -> DynamoDB: Update -> UpdateItem (parcial)
 *
 * A diferencia de SQL ("UPDATE turnos SET estado=? WHERE id=?"), en
 * DynamoDB no hay un UPDATE directo por un id "suelto": primero hay que
 * resolver PK+SK reales (vía GSI1, igual que en getTurno), y recién ahí
 * aplicar un UpdateItem que modifica solo los atributos indicados --
 * nunca se trae el item completo para pisarlo.
 */
exports.handler = async (event) => {
  const { turnoId } = event.pathParameters || {};
  const body = JSON.parse(event.body || '{}');
  const { estado, hora } = body;

  if (!turnoId) {
    return response(400, { message: 'Falta turnoId en el path' });
  }

  if (!estado && !hora) {
    return response(400, {
      message: 'Nada para actualizar: enviar estado y/o hora',
    });
  }

  // 1) Resolver la clave primaria real (PK, SK) a partir del turnoId.
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

  // 2) UpdateItem parcial: solo toca los atributos enviados.
  const updateParts = [];
  const values = {};

  if (estado) {
    updateParts.push('estado = :estado');
    values[':estado'] = estado;
  }
  if (hora) {
    updateParts.push('hora = :hora');
    values[':hora'] = hora;
  }

  const result = await docClient.send(
    new UpdateCommand({
      TableName: TABLE_NAME,
      Key: { PK, SK },
      UpdateExpression: `SET ${updateParts.join(', ')}`,
      ExpressionAttributeValues: values,
      ReturnValues: 'ALL_NEW',
    })
  );

  return response(200, result.Attributes);
};
