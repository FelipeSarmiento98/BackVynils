# Usa una imagen base de Alpine
FROM node:12-alpine

# Instalar dependencias necesarias para PostgreSQL
RUN apk add --no-cache postgresql postgresql-client

# Configurar PostgreSQL para escuchar en localhost
RUN echo "host all all 0.0.0.0/0 md5" >> /etc/postgresql/pg_hba.conf && \
    echo "listen_addresses='*'" >> /etc/postgresql/postgresql.conf

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

# Copiar script de inicio
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Exponer puerto para NestJS
EXPOSE 3000

# Comando para iniciar servicios
CMD ["/start.sh"]
