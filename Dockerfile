# Usa una imagen base de Alpine
FROM node:12-alpine

# Instalar dependencias necesarias para PostgreSQL
RUN apk add --no-cache postgresql postgresql-client

# Configurar usuario de PostgreSQL
RUN adduser -D postgres && \
    mkdir -p /var/lib/postgresql/data && \
    chown -R postgres:postgres /var/lib/postgresql/data

# Inicializar la base de datos (necesario para Alpine)
USER postgres
RUN initdb -D /var/lib/postgresql/data
USER root

# Configurar PostgreSQL para escuchar en todas las interfaces (ruta correcta)
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

# IMPORTANTE: Crear el script start.sh directamente en la imagen
RUN echo '#!/bin/sh\n\
\n\
# Iniciar PostgreSQL en Alpine (método correcto)\n\
echo "Iniciando PostgreSQL..."\n\
mkdir -p /run/postgresql\n\
chown -R postgres:postgres /run/postgresql\n\
su postgres -c "pg_ctl -D /var/lib/postgresql/data -l /var/lib/postgresql/logfile start"\n\
\n\
# Esperar a que PostgreSQL esté listo\n\
echo "Esperando a que PostgreSQL esté listo..."\n\
sleep 5\n\
\n\
# Configurar PostgreSQL\n\
su postgres -c "psql -c \"ALTER USER postgres WITH PASSWORD '"'"'postgres'"'"';\""\n\
su postgres -c "psql -c \"CREATE DATABASE vinyls;\" || true"\n\
\n\
# Iniciar la aplicación NestJS\n\
echo "Iniciando la aplicación..."\n\
cd /usr/src/app\n\
exec npm run start:prod\n\
' > /start.sh

# Hacer que el script sea ejecutable
RUN chmod +x /start.sh

# Exponer puerto para NestJS
EXPOSE 3000

# Comando para iniciar servicios
CMD ["/start.sh"]
