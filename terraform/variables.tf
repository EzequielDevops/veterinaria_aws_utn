variable "aws_region" {
  description = "Región de AWS donde se despliega el stack"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefijo usado para nombrar los recursos"
  type        = string
  default     = "turnos-vet"
}

variable "environment" {
  description = "Nombre del ambiente (demo, dev, prod)"
  type        = string
  default     = "demo"
}
