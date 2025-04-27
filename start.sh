#!/bin/bash

# Iniciar PostgreSQL en segundo plano
service postgresql start

# Esperar a que PostgreSQL esté listo
echo "Esperando a que PostgreSQL esté listo..."
sleep 5

# Configurar PostgreSQL
su - postgres -c "psql -c \"ALTER USER postgres WITH PASSWORD 'postgres';\""
su - postgres -c "psql -c \"CREATE DATABASE vinyls;\" || true"

# Iniciar la aplicación NestJS
echo "Iniciando la aplicación..."
cd /usr/src/app
npm run start:prod
