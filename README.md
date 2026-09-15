# PrestaShop Module Docker

A Docker-based development environment for building and testing a PrestaShop
module against multiple PrestaShop versions from the same working directory.

Each version has its own PrestaShop installation and database while sharing the
module source. This makes it possible to check compatibility without installing
PHP, MySQL, or PrestaShop directly on the host.

## Features

- Run any version published as an official
  [`prestashop/prestashop`](https://hub.docker.com/r/prestashop/prestashop/tags)
  image tag.
- Keep separate installations and databases for each PrestaShop version.
- Work on the module directly from the host.
- Choose the PrestaShop, MySQL, and PHPUnit PHP versions.
- Use Composer and the PrestaShop console inside Docker.
- Run PHPUnit, PHPStan, PHP_CodeSniffer, PHP CS Fixer, Auto Index, and Header
  Stamp.
- Access the database through Adminer and debug the shop with Xdebug.

## Quick Start

1. Clone the repository:

   ```bash
   git clone https://github.com/rubenmartindev/prestashop-module-docker.git
   cd prestashop-module-docker
   ```

2. Create your local configuration:

   ```bash
   cp .env.dist .env
   ```

3. Add your module source to `module/`.

   The repository includes `MyModule` as a working example. You can adapt it or
   replace the contents of `module/` with your own module. Set `MODULE_NAME` in
   `.env` to its PrestaShop technical name; it must match the module entry point.

   For a module whose entry point is `module/foobar.php`:

   ```dotenv
   MODULE_NAME=foobar
   ```

4. Start the environment:

   ```bash
   make up
   ```

The first start downloads the required images and installs PrestaShop, so it may
take a few minutes.

With the default configuration, open:

| Service | URL |
| --- | --- |
| Storefront | <http://localhost/> |
| Back office | <http://localhost/admin-dev/> |
| Adminer | <http://localhost:8080/> |

The default back-office credentials are:

```text
Email:    admin@example.com
Password: prestashop
```

For Adminer, select MySQL and use `db` as the server. The default database,
username, and password are all `prestashop`.

## Configuration

The main settings are stored in `.env`:

| Variable | Default | Purpose |
| --- | --- | --- |
| `MODULE_NAME` | `mymodule` | Technical name of the module |
| `PS` | `9` | PrestaShop image tag |
| `PS_HTTP_PORT` | `80` | Host port for the shop |
| `PS_DOMAIN` | `localhost` | Domain configured in PrestaShop |
| `DB_VERSION_TAG` | `5.7` | MySQL image tag |
| `ADMINER_PORT` | `8080` | Host port for Adminer |
| `PHPUNIT_PHP_VERSION` | `5.6` | PHP version used to run PHPUnit |

Other PrestaShop and database settings can be added to `.env` when the defaults
need to be changed. See `compose.yml` for the complete list of supported values.

When changing the shop port, update both `PS_HTTP_PORT` and `PS_DOMAIN`:

```dotenv
PS_HTTP_PORT=8080
PS_DOMAIN=localhost:8080
```

### Multiple PrestaShop Versions

The project supports a base environment file and additional version-specific
files. This lets you share common settings while customizing each PrestaShop
environment.

The `PS` variable selects the PrestaShop version. Set it in `.env` or pass it to
`make`. For example, when `PS=8.1`, the files are loaded in this order:

```text
.env
.env.8.1
.env.8.1.local
```

Values in later files override values from earlier files. Values passed to
`make` have the highest priority.

For example, keep the shared settings in `.env`:

```dotenv
MODULE_NAME=mymodule

DB_VERSION_TAG=5.7

PHPUNIT_PHP_VERSION=5.6
```

Then create `.env.8.1` with the settings for PrestaShop 8.1:

```dotenv
PS_HTTP_PORT=8080
PS_DOMAIN=localhost:8080

ADMINER_PORT=8888
```

Start the configured versions with Make:

```bash
make PS=1.6 up # .env > .env.1.6 > .env.1.6.local
make PS=8.1 up # .env > .env.8.1 > .env.8.1.local
make PS=9 up   # .env > .env.9 > .env.9.local
```

Each version keeps its own shop files and database while sharing the same
`module/` directory. Assign different ports in the version-specific files to
run several versions at the same time.

Use the same `PS` value when operating or stopping a specific environment:

```bash
make PS=8.1 ps
make PS=8.1 down
```

## Commands

Run `make help` after configuring `MODULE_NAME` to list all available commands.

### Environment

| Command | Description |
| --- | --- |
| `make build` | Build the PrestaShop image |
| `make up` | Start the selected environment |
| `make down` | Stop the environment while preserving its data |
| `make down-hard` | Delete the environment, its database, and generated shop |
| `make ps` | Show the environment status |
| `make logs` | Follow container logs |
| `make shell` | Open a shell in the module directory |
| `make console ARGS="..."` | Run the PrestaShop Symfony console |

### Module

| Command | Description |
| --- | --- |
| `make composer ARGS="..."` | Run Composer for the module |
| `make install` | Install the module in PrestaShop |
| `make uninstall` | Uninstall the module from PrestaShop |

Examples:

```bash
make composer ARGS="install"
make console ARGS="cache:clear"
make logs ARGS="prestashop"
```

### Quality and Tests

| Command | Description |
| --- | --- |
| `make phpunit` | Run the module test suite |
| `make phpstan` | Run static analysis |
| `make phpcs` | Check coding standards |
| `make cs-check` | Check formatting with PHP CS Fixer |
| `make qa` | Run all quality checks and tests |
| `make autoindex` | Add the recommended PrestaShop index files |
| `make header-stamp` | Apply source file headers |
| `make shell-tooling` | Open a shell with the quality tools |
| `make shell-phpunit` | Open a shell in the PHPUnit environment |

Pass options to an individual tool through `ARGS`:

```bash
make phpunit ARGS="--filter MyModuleTest"
make phpstan ARGS="--level=8"
make phpcs ARGS="--standard=PSR12"
```

Run `make up` first when a test or tool needs access to a generated PrestaShop
installation. The configurations included in `module/` are examples and can be
adapted to the requirements of your module.

`make autoindex` and `make header-stamp` modify module files. Review their
changes before committing them.

## Project Structure

```text
.docker/       Docker images and startup scripts
module/        Module source, dependencies, configuration, and tests
phpunit/       PHPUnit runner dependencies
prestashop/    Generated PrestaShop installations
tooling/       Quality tool dependencies
compose.yml    Service configuration
Makefile       Development commands
```

## Data and Cleanup

`make down` stops the selected environment but preserves its generated shop,
database, module source, and installed development dependencies.

`make down-hard` performs a complete reset of the selected PrestaShop
environment. It deletes its generated installation and database, but does not
delete the source in `module/`.

Always provide the intended version when resetting a non-default environment:

```bash
make PS=8.1 down-hard
```

## License

This project is licensed under the [MIT License](LICENSE).
