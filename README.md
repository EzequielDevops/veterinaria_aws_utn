# Turnos Veterinaria — CRUD Serverless (demo de charla)

Caso de estudio para la charla **"De la Facu al Mercado"** (UTN Community Day).
CRUD de turnos para veterinarias, implementado con:

- **Node.js** (handlers de AWS Lambda, sin framework, SDK v3)
- **Amazon DynamoDB** (tabla única, single-table design)
- **Amazon API Gateway** (HTTP API)
- **Terraform** (infraestructura como código)

## Arquitectura

```
Cliente ──> API Gateway (HTTP API) ──> Lambda (Node.js) ──> DynamoDB
```

Una función Lambda por operación CRUD. Cada una tiene su propio rol IAM con
el mínimo permiso necesario sobre la tabla (principio de mínimo privilegio).

## Modelo de datos (DynamoDB)

Tabla única `turnos-table`.

| Entidad      | PK              | SK                                  |
|--------------|-----------------|--------------------------------------|
| Veterinaria  | `VET#<vetId>`   | `METADATA`                           |
| Turno        | `VET#<vetId>`   | `TURNO#<fecha>#<hora>#<turnoId>`     |

- **Patrón de acceso "turnos de una vet en un día"**: `Query` sobre `PK` +
  `SK begins_with TURNO#<fecha>`.
- **Patrón de acceso "un turno por su ID"** (para `GET`, `PUT`, `DELETE` por
  id, sin conocer fecha ni vet): `GSI1` con `GSI1PK = TURNO_ID` fijo particionado
  por `turnoId`, en este demo simplificado a `GSI1PK = turnoId`, `GSI1SK = turnoId`.

Ver detalle completo en [`../charla/04-datos-dynamodb.md`](../charla/04-datos-dynamodb.md).

## Estructura del repo

```
app/
├── src/
│   ├── handlers/
│   │   ├── createTurno.js
│   │   ├── getTurno.js
│   │   ├── listTurnos.js
│   │   ├── updateTurno.js
│   │   └── deleteTurno.js
│   └── lib/
│       └── dynamo.js
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── dynamodb.tf
│   ├── lambda.tf
│   ├── iam.tf
│   └── api_gateway.tf
├── scripts/
│   └── init.sh
├── package.json
└── README.md
```

## Requisitos

- Terraform >= 1.5
- Una cuenta AWS con el perfil `e2ops_admin` configurado (`aws configure --profile e2ops_admin`)

No hace falta Node.js ni `npm install` para desplegar: los handlers solo
usan el SDK de AWS, que ya viene incluido en el runtime `nodejs20.x` de
Lambda, y el empaquetado (`.zip` por función) lo hace Terraform directo
con `data "archive_file"` (ver `terraform/lambda.tf`). Node.js solo se
necesita si se quiere correr `npm run lint` en local.

## Deploy

Con el bootstrapper (recomendado para la demo):

```bash
cd app
./scripts/init.sh        # init + plan + apply, usando el perfil e2ops_admin
./scripts/init.sh plan   # solo ver el plan
./scripts/init.sh destroy
```

> El script `scripts/init.sh` es temporal: se usa para parar y probar el
> stack durante la preparación de la charla, y se saca del repo una vez
> verificado el deploy (no se deja un atajo con un perfil admin colgado).

O a mano:

```bash
cd app/terraform
terraform init
terraform plan
terraform apply
```

Al finalizar, Terraform imprime la URL base de la API (`api_base_url`).

## Probar el CRUD

```bash
API_URL="<api_base_url de terraform output>"

# Crear turno
curl -X POST "$API_URL/turnos" \
  -H "Content-Type: application/json" \
  -d '{
    "vetId": "vet-001",
    "fecha": "2026-11-10",
    "hora": "09:00",
    "mascota": "Firulais",
    "duenio": "Juan Perez"
  }'

# Listar turnos de una vet en una fecha
curl "$API_URL/turnos?vetId=vet-001&fecha=2026-11-10"

# Obtener un turno por id
curl "$API_URL/turnos/<turnoId>"

# Modificar un turno (ej. cambiar estado)
curl -X PUT "$API_URL/turnos/<turnoId>" \
  -H "Content-Type: application/json" \
  -d '{"estado": "cancelado"}'

# Eliminar un turno
curl -X DELETE "$API_URL/turnos/<turnoId>"
```

## Destruir infraestructura

```bash
./scripts/init.sh destroy
# o a mano:
cd terraform
terraform destroy
```

## Notas de diseño (pensadas para la charla)

- **Sin framework HTTP** en los handlers: se usa el SDK de DynamoDB directo
  para que el código mostrado en pantalla sea legible línea por línea en
  los ~7-8 minutos de cada bloque.
- **Una Lambda por operación**, no un router monolítico. Hace más explícito
  el mapeo CRUD → función → permiso IAM, que es justo el punto pedagógico
  del bloque de Security.
- **HTTP API (no REST API)** de API Gateway: más barato y más simple de
  declarar en Terraform, consistente con el pilar de Cost Optimization.
- **Empaquetado 100% en Terraform** (`data "archive_file"`), sin script de
  shell ni `node_modules`: los handlers solo dependen del SDK de AWS
  (incluido en el runtime) y de `crypto.randomUUID()` nativo de Node, así
  que no hace falta `npm install` para desplegar.
# veterinaria_aws_utn
