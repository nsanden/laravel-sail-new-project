#!/bin/bash

# Check for project name passed as an argument, default to "myLaravelProject" if none
PROJECT_NAME="${1:-myLaravelProject}"

# Create the project directory and navigate into it
mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME" || exit

echo "Creating Laravel project named $PROJECT_NAME..."

# Step 1: Run the Docker command to create a new Laravel project with Sail
docker run --rm \
    -u "$(id -u):$(id -g)" \
    -v "$(pwd):/var/www/html" \
    -w /var/www/html \
    laravelsail/php83-composer:latest \
    bash -c "composer create-project laravel/laravel . --prefer-dist && composer require laravel/sail --dev && php artisan sail:install"

# Check if the Laravel project was created successfully and the docker-compose.yml exists
if [ ! -f "docker-compose.yml" ];
then
    echo "The Laravel project was not created successfully. Exiting..."
    exit 1
fi

# Step 2: Append 'TEST' to the docker-compose.yml
cat << 'EOF' > docker-compose.yml
services:
    laravel.test:
        build:
            context: ./vendor/laravel/sail/runtimes/8.3
            dockerfile: Dockerfile
            args:
                WWWGROUP: '${WWWGROUP}'
        image: sail-8.3/app
        extra_hosts:
            - 'host.docker.internal:host-gateway'
        ports:
            - '${APP_PORT:-80}:80'
            - '${VITE_PORT:-5173}:${VITE_PORT:-5173}'
        environment:
            WWWUSER: '${WWWUSER}'
            LARAVEL_SAIL: 1
            XDEBUG_MODE: '${SAIL_XDEBUG_MODE:-off}'
            XDEBUG_CONFIG: '${SAIL_XDEBUG_CONFIG:-client_host=host.docker.internal}'
            IGNITION_LOCAL_SITES_PATH: '${PWD}'
        volumes:
            - '.:/var/www/html'
        networks:
            - sail
        depends_on:
            - mysql
            - redis
            - meilisearch
            - mailpit
            - selenium
    mysql:
        image: 'mysql/mysql-server:8.0'
        ports:
            - '${FORWARD_DB_PORT:-3306}:3306'
        environment:
            MYSQL_ROOT_PASSWORD: '${DB_PASSWORD}'
            MYSQL_ROOT_HOST: '%'
            MYSQL_DATABASE: '${DB_DATABASE}'
            MYSQL_USER: '${DB_USERNAME}'
            MYSQL_PASSWORD: '${DB_PASSWORD}'
            MYSQL_ALLOW_EMPTY_PASSWORD: 1
        volumes:
            - 'sail-mysql:/var/lib/mysql'
            - './vendor/laravel/sail/database/mysql/create-testing-database.sh:/docker-entrypoint-initdb.d/10-create-testing-database.sh'
        networks:
            - sail
        healthcheck:
            test:
                - CMD
                - mysqladmin
                - ping
                - '-p${DB_PASSWORD}'
            retries: 3
            timeout: 5s
    redis:
        image: 'redis:alpine'
        ports:
            - '${FORWARD_REDIS_PORT:-6379}:6379'
        volumes:
            - 'sail-redis:/data'
        networks:
            - sail
        healthcheck:
            test:
                - CMD
                - redis-cli
                - ping
            retries: 3
            timeout: 5s
    meilisearch:
        image: 'getmeili/meilisearch:latest'
        ports:
            - '${FORWARD_MEILISEARCH_PORT:-7700}:7700'
        environment:
            MEILI_NO_ANALYTICS: '${MEILISEARCH_NO_ANALYTICS:-false}'
        volumes:
            - 'sail-meilisearch:/meili_data'
        networks:
            - sail
        healthcheck:
            test:
                - CMD
                - wget
                - '--no-verbose'
                - '--spider'
                - 'http://localhost:7700/health'
            retries: 3
            timeout: 5s
    mailpit:
        image: 'axllent/mailpit:latest'
        ports:
            - '${FORWARD_MAILPIT_PORT:-1025}:1025'
            - '${FORWARD_MAILPIT_DASHBOARD_PORT:-8025}:8025'
        networks:
            - sail
    selenium:
        image: selenium/standalone-chrome
        extra_hosts:
            - 'host.docker.internal:host-gateway'
        volumes:
            - '/dev/shm:/dev/shm'
        networks:
            - sail
    phpmyadmin:
        image: phpmyadmin/phpmyadmin
        ports:
            - '8080:80'
        environment:
            PMA_HOST: mysql  # Replace 'mysql' with the name of your MySQL service
            PMA_PORT: 3306   # Replace with the port your MySQL service is exposed on if different
            MYSQL_ROOT_PASSWORD: '${DB_PASSWORD}'  # Use the same root password as your MySQL service
        networks:
            - sail
networks:
    sail:
        driver: bridge
volumes:
    sail-mysql:
        driver: local
    sail-redis:
        driver: local
    sail-meilisearch:
        driver: local
EOF

# Step 3: Edit the .bashrc to include the alias for Sail
# This checks for the presence of the alias and adds it if it doesn't already exist
if ! grep -q "alias sail=" ~/.bashrc; then
    echo "alias sail='sh \$([ -f sail ] && echo sail || echo vendor/bin/sail)'" >> ~/.bashrc
    echo "Sail alias added to your .bashrc."
    source ~/.bashrc
else
    echo "Sail alias already exists in your .bashrc."
fi
