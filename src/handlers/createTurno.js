'use strict';

const { randomUUID } = require('crypto');
const { PutCommand } = require('@aws-sdk/lib-dynamodb');
const { docClient, TABLE_NAME, response } = require('../lib/dynamo');

/**
 * CREATE — POST /turnos
 *
 * Mapeo CRUD -> DynamoDB: Create -> PutItem
 *
 * Diseño de claves:
 *   PK = VET#<vetId>
 *   SK = TURNO#<fecha>#<hora>#<turnoId>
 *
 * El SK se construye para que un turno de una vet en una fecha quede
 * ordenado y sea "query-able" por prefijo (begins_with), sin necesitar
 * un JOIN ni un WHERE con scan de tabla completa.
 */
exports.handler = async (event) => {
  const body = JSON.parse(event.body || '{}');
  const { vetId, fecha, hora, mascota, duenio } = body;

  if (!vetId || !fecha || !hora || !mascota || !duenio) {
    return response(400, {
      message: 'Campos requeridos: vetId, fecha, hora, mascota, duenio',
    });
  }

  const turnoId = randomUUID();

  const item = {
    PK: `VET#${vetId}`,
    SK: `TURNO#${fecha}#${hora}#${turnoId}`,
    GSI1PK: turnoId,
    GSI1SK: turnoId,
    turnoId,
    vetId,
    fecha,
    hora,
    mascota,
    duenio,
    estado: 'confirmado',
    createdAt: new Date().toISOString(),
  };

  await docClient.send(
    new PutCommand({
      TableName: TABLE_NAME,
      Item: item,
      // Evita pisar un turno ya existente con la misma clave (misma vet,
      // fecha, hora y id generado -- defensivo, el id es UUID).
      ConditionExpression: 'attribute_not_exists(PK)',
    })
  );

  return response(201, item);
};
