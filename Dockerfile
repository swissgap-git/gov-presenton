FROM python:3.11-slim-bookworm

# Install Node.js, npm and additional dependencies
RUN apt-get update && apt-get install -y \
    nodejs \  
    npm \
    nginx \
    curl \
    redis-server \
    zstd \
    wget \
    fonts-liberation \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libatspi2.0-0 \
    libcairo2 \
    libcups2 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libpango-1.0-0 \
    libvulkan1 \
    libxdamage1 \
    libxkbcommon0 \
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

# Install chrome for puppeteer (dependencies already installed above)
RUN npx puppeteer browsers install chrome

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