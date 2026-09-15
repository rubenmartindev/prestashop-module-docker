RED   			:= $(shell printf '\e[0;31m')
BLUE			:= $(shell printf '\e[0;33m')
YELLOW			:= $(shell printf '\e[0;33m')
CYAN_UNDERLINE	:= $(shell printf '\e[4;36m')

RESET			:= $(shell printf '\e[0m')

-include .env

PS				?= 9
PS_VERSION_TAG	:= $(PS)

-include .env.$(PS_VERSION_TAG)
-include .env.$(PS_VERSION_TAG).local

export

ifndef MODULE_NAME
$(error $(RED)ERRROR:$(RESET) The $(YELLOW)MODULE_NAME$(RESET) environment variable is not defined)
endif

HOST_UID 				?= $(shell id -u)
HOST_GID 				?= $(shell id -g)

PS_HTTP_PORT 			?= 80

PHPUNIT_PHP_VERSION		?= 8.5

ARGS 					?=

COMPOSE_PROJECT_NAME	:= $(MODULE_NAME)-$(subst .,-,$(PS_VERSION_TAG))
COMPOSE 				:= docker compose --project-name $(COMPOSE_PROJECT_NAME)
PHPUNIT_COMPOSE			:= $(COMPOSE) --profile=phpunit
PRESTASHOP_COMPOSE		:= $(COMPOSE) --profile=prestashop
TOOLING_COMPOSE			:= $(COMPOSE) --profile=tooling

.DEFAULT_GOAL 			:= help
.PHONY: \
	help \
	build up down down-hard logs ps shell console \
	shell-tooling shell-phpunit shell-tests phpstan phpcs cs-check phpunit tests qa autoindex header-stamp \
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
	@mkdir -p "./prestashop/$(PS_VERSION_TAG)"
	@$(PRESTASHOP_COMPOSE) up \
		--wait \
		--detach \
		$(ARGS)
	@echo ""
	@echo "Services URLs:"
	@echo " - $(YELLOW)PrestaShop (Frontend):$(RESET) $(CYAN_UNDERLINE)http://$(PS_DOMAIN)$(RESET)"
	@echo " - $(YELLOW)PrestaShop (Backend):$(RESET)  $(CYAN_UNDERLINE)http://$(PS_DOMAIN)/$(PS_FOLDER_ADMIN)$(RESET)"
	@echo " - $(YELLOW)Adminer:$(RESET)               $(CYAN_UNDERLINE)http://localhost:$(ADMINER_PORT)$(RESET)"

down: ## Stop and remove the PrestaShop container
	@$(PRESTASHOP_COMPOSE) down \
		--remove-orphans \
		$(ARGS)

down-hard: ## Stop and delete containers, volumes and the installation of PrestaShop
	@$(PRESTASHOP_COMPOSE) down \
		--remove-orphans \
		--volumes \
		$(ARGS)
	@if [ -d "./prestashop/$(PS_VERSION_TAG)" ]; then \
		rm -rf "./prestashop/$(PS_VERSION_TAG)"; \
		echo " ✔ Folder deleted: prestashop/$(PS_VERSION_TAG)"; \
	fi

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
		prestashop bash

console: ## Run the Symfony console in the PrestaShop container
	@$(PRESTASHOP_COMPOSE) exec \
		--user=www-data \
		prestashop bin/console \
		$(ARGS)

## —— 🛠 Tooling & Tests ———————————————————————————————————————————————————————

shell-tooling: ## Open a shell in the Tooling container
	@$(TOOLING_COMPOSE) run \
		--rm \
		--workdir=/app/tooling \
		tooling bash

shell-phpunit: ## Open a shell in the PHPUnit container
	@$(PHPUNIT_COMPOSE) run \
		--rm \
		--workdir=/app/phpunit \
		phpunit bash

shell-tests: shell-phpunit ## Alias for 'make shell-phpunit'

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

phpunit: ## Run PHPUnit in the PHPUnit container
	@$(PHPUNIT_COMPOSE) run \
		--rm phpunit \
		/app/phpunit/vendor/bin/phpunit \
		$(ARGS)

tests: phpunit ## Alias for 'make phpunit'

qa: override ARGS :=
qa: cs-check phpcs phpstan phpunit ## Run all quality checks

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
