RED   	:= $(shell printf '\033[31m')
YELLOW	:= $(shell printf '\033[33m')
RESET	:= $(shell printf '\033[0m')

-include .env

PS_VERSION_TAG ?= 9

-include .env.$(PS_VERSION_TAG)
-include .env.$(PS_VERSION_TAG).local

export

ifndef MODULE_NAME
$(error $(RED)ERRROR:$(RESET) The $(YELLOW)MODULE_NAME$(RESET) environment variable is not defined)
endif

HOST_UID 				?= $(shell id -u)
HOST_GID 				?= $(shell id -g)

PS_HTTP_PORT 			?= 80

TESTS_PHP_VERSION		?= 8.5

ARGS 					?=

COMPOSE_PROJECT_NAME	:= $(MODULE_NAME)-$(subst .,-,$(PS_VERSION_TAG))
COMPOSE 				:= docker compose --project-name $(COMPOSE_PROJECT_NAME)
PRESTASHOP_COMPOSE		:= $(COMPOSE) --profile=prestashop
TESTS_COMPOSE			:= $(COMPOSE) --profile=tests
TOOLING_COMPOSE			:= $(COMPOSE) --profile=tooling

.DEFAULT_GOAL 			:= help
.PHONY: \
	help \
	build up down logs ps shell console \
	phpstan phpcs cs-check tests qa autoindex header-stamp \
	composer install uninstall

## —— 🌟 Makefile 🌟 ———————————————————————————————————————————————————————————

help: ## Show this help
	@grep -hE '(^[a-zA-Z0-9\./_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}{printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

## —— 🐧 PrestaShop ————————————————————————————————————————————————————————————

build: ## Build the PrestaShop image
	@$(PRESTASHOP_COMPOSE) build \
		--pull \
		$(ARGS)

up: ## Start the PrestaShop container
	@mkdir -p prestashop/$(PS_VERSION_TAG)
	@$(PRESTASHOP_COMPOSE) up \
		--wait \
		--detach \
		$(ARGS)

down: ## Stop and remove the PrestaShop container
	@$(PRESTASHOP_COMPOSE) down \
		--remove-orphans \
		$(ARGS)

logs: ## Follow the container logs
	@$(PRESTASHOP_COMPOSE) logs \
		--follow \
		$(ARGS)

ps: ## Show the container status
	@$(PRESTASHOP_COMPOSE) ps \
		$(ARGS)

shell: ## Open a shell in the PrestaShop container
	@$(PRESTASHOP_COMPOSE) exec \
		--user=www-data \
		--workdir=/var/www/html/modules/$(MODULE_NAME) \
		prestashop bash \
		$(ARGS)

console: ## Run the Symfony console in the PrestaShop container
	@$(PRESTASHOP_COMPOSE) exec \
		--user=www-data \
		prestashop bin/console \
		$(ARGS)

## —— 🛠 Tooling & Tests ———————————————————————————————————————————————————————

phpstan: ## Run PHPStan in the Tooling container
	@$(TOOLING_COMPOSE) run \
		--rm tooling \
		/app/tooling/vendor/bin/phpstan \
		analyse \
		$(ARGS)

phpcs: ## Run PHP_CodeSniffer in the Tooling container
	@$(TOOLING_COMPOSE) run \
		--rm tooling \
		/app/tooling/vendor/bin/phpcs \
		$(ARGS)

cs-check: ## Run PHP CS Fixer in the Tooling container in dry-run mode
	@$(TOOLING_COMPOSE) run \
		--rm tooling \
		/app/tooling/vendor/bin/php-cs-fixer fix \
		--dry-run \
		--diff \
		$(ARGS)

tests: ## Run PHPUnit in the Tests container
	@$(TESTS_COMPOSE) run \
		--rm tests \
		/app/tests/vendor/bin/phpunit \
		$(ARGS)

qa: override ARGS :=
qa: cs-check phpcs phpstan tests ## Run all quality checks

autoindex: ## Run Auto Index in the Tooling container
	@$(TOOLING_COMPOSE) run \
		--rm tooling \
		/app/tooling/vendor/bin/autoindex \
		prestashop:add:index \
		--exclude=vendor,tests \
		$(ARGS)

header-stamp: ## Run Header Stamp in the Tooling container
	@$(TOOLING_COMPOSE) run \
		--rm tooling \
		/app/tooling/vendor/bin/header-stamp \
		--exclude=vendor,tests \
		$(ARGS)

## —— 🧩 Module ————————————————————————————————————————————————————————————————

composer: ## Run Composer in the module
	@$(PRESTASHOP_COMPOSE) exec \
		--user=www-data \
		--workdir=/var/www/html/modules/$(MODULE_NAME) \
		prestashop composer \
		$(ARGS)

install: ## Install the module
	@$(PRESTASHOP_COMPOSE) exec \
		--user=www-data \
		prestashop \
		/tmp/module/install

uninstall: ## Uninstall the module
	@$(PRESTASHOP_COMPOSE) exec \
		--user=www-data \
		prestashop \
		/tmp/module/uninstall
