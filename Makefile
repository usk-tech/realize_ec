.PHONY: help up down restart shell console logs setup install migrate db-create db-migrate db-seed db-reset test clean

# Default target
help:
	@echo "Available commands:"
	@echo "  make up              - Start all Docker containers"
	@echo "  make down            - Stop all Docker containers"
	@echo "  make restart         - Restart all Docker containers"
	@echo "  make shell           - Open shell in Rails container"
	@echo "  make console         - Open Rails console"
	@echo "  make logs            - Show logs from all containers"
	@echo "  make setup           - Initial setup (bundle install + db setup)"
	@echo "  make install         - Run bundle install"
	@echo "  make migrate         - Run database migrations"
	@echo "  make db-create       - Create database"
	@echo "  make db-migrate      - Run migrations"
	@echo "  make db-seed         - Seed database"
	@echo "  make db-reset        - Reset database (drop, create, migrate, seed)"
	@echo "  make test            - Run RSpec tests"
	@echo "  make clean           - Clean up Docker containers and volumes"

# Docker operations
up:
	cd .devcontainer && docker compose up -d

down:
	cd .devcontainer && docker compose down

restart:
	cd .devcontainer && docker compose restart

logs:
	cd .devcontainer && docker compose logs -f

# Container access
shell:
	cd .devcontainer && docker compose exec rails-app bash

console:
	cd .devcontainer && docker compose exec rails-app bundle exec rails console

# Setup and installation
setup:
	cd .devcontainer && docker compose exec rails-app bash -c "bundle install && bundle exec rails db:create db:migrate db:seed"

install:
	cd .devcontainer && docker compose exec rails-app bundle install

# Database operations
db-create:
	cd .devcontainer && docker compose exec rails-app bundle exec rails db:create

db-migrate:
	cd .devcontainer && docker compose exec rails-app bundle exec rails db:migrate

db-seed:
	cd .devcontainer && docker compose exec rails-app bundle exec rails db:seed

db-reset:
	cd .devcontainer && docker compose exec rails-app bundle exec rails db:drop db:create db:migrate db:seed

migrate: db-migrate

# Testing
test:
	cd .devcontainer && docker compose exec rails-app bundle exec rspec

# Cleanup
clean:
	cd .devcontainer && docker compose down -v
	docker system prune -f
