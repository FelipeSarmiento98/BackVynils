# Usar una imagen base más compatible
FROM node:12-alpine

# Instalar dependencias necesarias para PostgreSQL
RUN apk add --no-cache postgresql postgresql-client

# Crear directorio de datos para PostgreSQL si no existe
RUN mkdir -p /var/lib/postgresql/data && \
    chown -R postgres:postgres /var/lib/postgresql/data

# Inicializar la base de datos como usuario postgres
USER postgres
RUN initdb -D /var/lib/postgresql/data
USER root

# Configurar PostgreSQL para escuchar en todas las interfaces
RUN echo "host all all 0.0.0.0/0 md5" >> /var/lib/postgresql/data/pg_hba.conf && \
    echo "listen_addresses='*'" >> /var/lib/postgresql/data/postgresql.conf

# Crear directorio de trabajo
WORKDIR /usr/src/app

# Copiar archivos de package.json y package-lock.json
COPY package*.json ./

# Instalar dependencias
RUN npm install --quiet

# Copiar el resto de archivos de la aplicación
COPY . .

# Compilar la aplicación
RUN npm run build

# SOLUCIÓN CRÍTICA: Crear un script de shell simple pero efectivo
RUN echo '#!/bin/sh' > /entrypoint.sh && \
    echo 'set -e' >> /entrypoint.sh && \
    echo 'mkdir -p /run/postgresql' >> /entrypoint.sh && \
    echo 'chown -R postgres:postgres /run/postgresql' >> /entrypoint.sh && \
    echo 'su postgres -c "pg_ctl -D /var/lib/postgresql/data -l /var/lib/postgresql/logfile start"' >> /entrypoint.sh && \
    echo 'sleep 5' >> /entrypoint.sh && \
    echo 'su postgres -c "psql -c \"ALTER USER postgres WITH PASSWORD '"'"'postgres'"'"';\""' >> /entrypoint.sh && \
    echo 'su postgres -c "psql -c \"CREATE DATABASE vinyls;\" 2>/dev/null || echo \"Base de datos vinyls ya existe\""' >> /entrypoint.sh && \
    echo 'cd /usr/src/app' >> /entrypoint.sh && \
    echo 'npm run start:prod' >> /entrypoint.sh && \
    chmod +x /entrypoint.sh

# Exponer puerto para NestJS
EXPOSE 3000

# Usar el script de inicio simplificado
CMD ["/bin/sh", "/entrypoint.sh"]
