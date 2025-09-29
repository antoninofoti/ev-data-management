FROM python:3.12-slim

# Installa dipendenze sistema incluso gnupg
RUN apt-get update && apt-get install -y \
    gnupg \
    build-essential \
    curl \
    git \
    wget \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

# Installa MongoDB tools
RUN curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | \
    gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg] http://repo.mongodb.org/apt/debian bullseye/mongodb-org/7.0 main" | \
    tee /etc/apt/sources.list.d/mongodb-org-7.0.list && \
    apt-get update && apt-get install -y mongodb-mongosh mongodb-database-tools

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

RUN pip install kaggle

RUN mkdir -p data/{raw,sql,nosql,processed} logs

COPY . .

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8888 8000

ENTRYPOINT ["/entrypoint.sh"]
