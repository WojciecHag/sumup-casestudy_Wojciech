# Use official dbt Docker image
FROM ghcr.io/dbt-labs/dbt-postgres:latest

# Set work directory
WORKDIR /usr/app

# Copy project files
COPY . .

# Install dependencies
RUN dbt deps

# Set entrypoint command
ENTRYPOINT ["dbt"]