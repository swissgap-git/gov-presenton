FROM python:3.11-slim-bookworm

# Install Node.js, npm and additional dependencies
RUN apt-get update && apt-get install -y \
    nodejs \  
    npm \
    nginx \
    curl \
    redis-server \
    zstd \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user and group
RUN groupadd -r presenton && useradd -r -g presenton -d /app -s /bin/bash presenton

# Create a working directory
WORKDIR /app  

# Set environment variables
ENV APP_DATA_DIRECTORY=/app/user_data
ENV TEMP_DIRECTORY=/tmp/presenton

# Install ollama
RUN curl -fsSL https://ollama.com/install.sh | sh

# Install dependencies for FastAPI
COPY servers/fastapi/requirements.txt ./
RUN pip install -r requirements.txt

# Install dependencies for Next.js
WORKDIR /app/servers/nextjs
COPY servers/nextjs/package.json servers/nextjs/package-lock.json ./
RUN npm install

# Install chrome for puppeteer
RUN npx puppeteer browsers install chrome --install-deps

# Copy Next.js app
COPY servers/nextjs/ /app/servers/nextjs/

# Build the Next.js app
WORKDIR /app/servers/nextjs
RUN npm run build

WORKDIR /app

# Copy FastAPI and start script
COPY servers/fastapi/ ./servers/fastapi/
COPY start.js LICENSE NOTICE ./

# Copy nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Change ownership of app directory to presenton user
RUN chown -R presenton:presenton /app

# Expose the port
EXPOSE 80

# Switch to non-root user
USER presenton

# Start the servers
CMD ["/bin/bash", "-c", "node /app/start.js"]