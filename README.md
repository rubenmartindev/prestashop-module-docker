# PrestaShop Module Docker

A Docker-based development environment for building and testing a PrestaShop
module against multiple PrestaShop versions from the same working directory.

Each PrestaShop version runs as an independent Docker Compose project and keeps
its own installation and database. The module source is shared across all of
them, making it easy to verify compatibility without maintaining separate
copies of the module.

## Features

- Run any PrestaShop version available as an official
  [`prestashop/prestashop`](https://hub.docker.com/r/prestashop/prestashop/tags)
  image tag.
- Keep an independent PrestaShop installation and database per version.
- Develop the module directly from the host through a bind mount.
- Choose the MySQL version used by each environment.
- Run PHPUnit with a configurable PHP version.
- Run PHPStan, PHP_CodeSniffer, PHP CS Fixer, Auto Index, and Header Stamp with
  PHP 8.5.
- Use Composer and the PrestaShop Symfony console without installing PHP on the
  host.
- Debug the running shop with Xdebug.

## Quick Start

1. Clone the repository and enter its directory:

   ```bash
   git clone https://github.com/rubenmartindev/prestashop-module-docker.git
   cd prestashop-module-docker
   ```

2. Create the local environment file:

   ```bash
   cp .env.dist .env
   ```

3. Put the module source in `module/`. The repository includes a minimal
   `mymodule` example that works with the default configuration.

   `MODULE_NAME` must match the module's PrestaShop technical name. For example,
   a module named `foobar` should have its entry point at
   `module/foobar.php` and use:

   ```dotenv
   MODULE_NAME=foobar
   ```

4. Start the environment:

   ```bash
   make up
   ```

The initial download, build, and automatic PrestaShop installation may take a
few minutes.

With the default values, the services are available at:

| Service | URL |
| --- | --- |
| Storefront | <http://localhost/> |
| Back office | <http://localhost/admin-dev/> |
| Adminer | <http://localhost:8080/> |

### Default Credentials

The default back-office credentials are:

```text
Email:    admin@example.com
Password: prestashop
```

For Adminer, select MySQL and use:

```text
Server:   db
Database: prestashop
Username: prestashop
Password: prestashop
```

## Project Structure

```text
.
|-- .docker/       Dockerfiles, entrypoints, and PrestaShop helper scripts
|-- module/        Module source shared by all PrestaShop environments
|-- phpunit/       PHPUnit Composer dependencies
|-- prestashop/    Generated PrestaShop installations, grouped by image tag
|   |-- 1.6/
|   |-- 8.1/
|   `-- ...
|-- tooling/       Development-tool Composer dependencies
|-- .env.dist      Ready-to-use environment configuration example
|-- compose.yml    Docker Compose services
`-- Makefile       Main development interface
```

For example, `PS=1.6` stores the generated shop files in
`prestashop/1.6/`. These files persist when the containers are stopped and are
excluded from Git.

## Working with Multiple PrestaShop Versions

The Docker Compose project name is generated from `MODULE_NAME` and `PS`. Dots
in the version tag are replaced with hyphens:

```text
MODULE_NAME=foobar
PS=8.1

Project name: foobar-8-1
```

You can select a version in `.env` or pass it directly to Make:

```bash
make PS=1.6 MODULE_NAME=mymodule up
make PS=8.1 MODULE_NAME=mymodule up
make PS=9 MODULE_NAME=mymodule up
```

Each command uses a different project, PrestaShop directory, and database
volume while mounting the same `module/` directory.

Use the same version variables when running commands or stopping a specific
environment:

```bash
make PS=8.1 down
```

## Environment Configuration

The Makefile loads optional environment files in this order:

1. `.env`
2. `.env.<PS>`
3. `.env.<PS>.local`

Values in later files override values from earlier files. Variables passed on
the `make` command line have the highest priority.

For example, when `PS=8.1`, the following files are loaded:

```text
.env
.env.8.1
.env.8.1.local
```

This allows shared defaults in `.env`, version-specific settings in
`.env.8.1`, and machine-local overrides in `.env.8.1.local`. Local environment
files are ignored by Git; `.env.dist` is the committed example.

### Configuration Example

The base `.env` file can contain the settings shared by every PrestaShop
version:

```dotenv
MODULE_NAME=mymodule

DB_VERSION_TAG=5.7
DB_NAME=prestashop
DB_USER=prestashop
DB_PASSWORD=prestashop
DB_ROOT_PASSWORD=root

PS_ADMIN_MAIL=admin@example.com
PS_ADMIN_PASSWD=prestashop
```

Each version-specific file can then define its own ports and domain. For
PrestaShop 1.6, create `.env.1.6`:

```dotenv
PS_HTTP_PORT=8016
PS_DOMAIN=localhost:8016
ADMINER_PORT=9016
```

For PrestaShop 8.1, create `.env.8.1`:

```dotenv
PS_HTTP_PORT=8081
PS_DOMAIN=localhost:8081
ADMINER_PORT=9081
```

For PrestaShop 9, create `.env.9`:

```dotenv
PS_HTTP_PORT=8090
PS_DOMAIN=localhost:8090
ADMINER_PORT=9090
```

Select the configuration by passing its PrestaShop tag to Make:

```bash
make PS=1.6 up
make PS=8.1 up
make PS=9 up
```

The three environments use the shared settings from `.env` and their own
version-specific ports, so they can run at the same time. Local overrides can
still be added to `.env.1.6.local`, `.env.8.1.local`, or `.env.9.local`.

Use the Make targets rather than calling `docker compose` directly. In addition
to the environment-file layering, Make calculates the host UID and GID and
selects the correct Compose profile and project name.

### Variables

| Variable | Default | Description |
| --- | --- | --- |
| `MODULE_NAME` | Required | PrestaShop technical module name and project-name prefix |
| `PS` | `9` | Official PrestaShop Docker image tag and installation directory |
| `PS_HTTP_PORT` | `80` | Host port for PrestaShop |
| `PS_DOMAIN` | `localhost:80` in `.env.dist` | Domain and port configured in PrestaShop |
| `PS_FOLDER_ADMIN` | `admin-dev` | Back-office directory name |
| `PS_ADMIN_MAIL` | `admin@example.com` | Initial administrator email |
| `PS_ADMIN_PASSWD` | `prestashop` | Initial administrator password |
| `PS_DEV_MODE` | `1` | Enable PrestaShop development mode |
| `PS_INSTALL_AUTO` | `1` | Enable automatic PrestaShop installation |
| `DB_VERSION_TAG` | `5.7` | Official MySQL Docker image tag |
| `DB_NAME` | `prestashop` | Database name |
| `DB_USER` | `prestashop` | Database user |
| `DB_PASSWORD` | `prestashop` | Database user password |
| `DB_ROOT_PASSWORD` | `root` | MySQL root password |
| `ADMINER_PORT` | `8080` | Host port for Adminer |
| `TESTS_PHP_VERSION` | `8.5` | PHP Docker image version used by PHPUnit |
| `HOST_UID` | Current user ID | UID used by `www-data` in the PrestaShop image |
| `HOST_GID` | Current group ID | GID used by `www-data` in the PrestaShop image |
| `XDEBUG_CONFIG` | `client_host=host.docker.internal` | Runtime Xdebug configuration |

If `PS_DOMAIN` is explicitly set, changing only `PS_HTTP_PORT` does not update
it. Change both values together when using a non-default port.

## Services

### `prestashop`

Builds on the official PrestaShop image selected by `PS`. The generated
installation is mounted from `prestashop/<PS>/`, while the local `module/`
directory is mounted at
`/var/www/html/modules/<MODULE_NAME>`.

Composer and Xdebug are installed in this image. Xdebug uses port `9003`, modes
`debug,develop`, and starts when triggered. By default it connects back to the
host at `host.docker.internal`.

### `db`

Runs the official MySQL image selected by `DB_VERSION_TAG`. Its data is stored
in a named Docker volume belonging to the generated Compose project. MySQL is
available to the other containers as `db:3306`; it is not exposed directly on
the host.

### `adminer`

Provides browser-based database access. It is exposed on `ADMINER_PORT`, which
defaults to `8080`.

### `tooling`

Uses PHP 8.5 so the latest compatible releases of the development tools can be
used independently of the PHP version bundled with PrestaShop:

- [PHPStan](https://github.com/phpstan/phpstan)
- [PHP_CodeSniffer](https://github.com/PHPCSStandards/PHP_CodeSniffer)
- [PHP CS Fixer](https://github.com/PHP-CS-Fixer/PHP-CS-Fixer)
- [PrestaShop Auto Index](https://github.com/PrestaShopCorp/autoindex)
- [PrestaShop Header Stamp](https://github.com/PrestaShopCorp/header-stamp)

The container runs as a non-root user. Its Composer project is stored in
`tooling/`, and dependencies are installed automatically in `tooling/vendor/`
the first time a tooling command or shell is started.

### `phpunit`

Runs PHPUnit in a separate PHP CLI image. Change `TESTS_PHP_VERSION` to test
with the PHP version required by the selected PrestaShop/module combination.
The container runs as a non-root user and installs the locked dependencies from
`phpunit/composer.lock` into `phpunit/vendor/` when first started.

## Make Commands

Run `make help` to display the available targets. A configured `MODULE_NAME` is
required by every target.

### PrestaShop Lifecycle

| Command | Description |
| --- | --- |
| `make build` | Build the PrestaShop image and pull newer base images |
| `make up` | Create the version directory, start the services, and print their URLs |
| `make down` | Stop and remove the environment containers |
| `make down-hard` | Stop the environment and delete its containers, volumes, and generated PrestaShop installation |
| `make logs` | Follow container logs |
| `make ps` | Show the environment status |
| `make shell` | Open Bash as `www-data` in the mounted module directory |
| `make console ARGS="..."` | Run the PrestaShop Symfony console |

Examples:

```bash
make logs ARGS="prestashop"
make shell
make console ARGS="cache:clear"
```

### Module Development

| Command | Description |
| --- | --- |
| `make composer ARGS="..."` | Run Composer in the module directory |
| `make install` | Install the module in the running PrestaShop instance |
| `make uninstall` | Uninstall the module from the running PrestaShop instance |

Examples:

```bash
make composer ARGS="install"
make composer ARGS="require vendor/package"
make install
make uninstall
```

If `module/composer.json` exists, its dependencies are also installed during
the initial PrestaShop setup.

### Quality and Tests

| Command | Description |
| --- | --- |
| `make phpstan` | Run PHPStan analysis |
| `make phpcs` | Run PHP_CodeSniffer |
| `make cs-check` | Run PHP CS Fixer in dry-run mode and show the diff |
| `make shell-tooling` | Open Bash in the tooling container |
| `make shell-phpunit` | Open Bash in the PHPUnit container |
| `make shell-tests` | Alias for `make shell-phpunit` |
| `make phpunit` | Run PHPUnit |
| `make tests` | Alias for `make phpunit` |
| `make qa` | Run `cs-check`, `phpcs`, `phpstan`, and `phpunit` |
| `make autoindex` | Add PrestaShop index files, excluding `vendor` and `tests` |
| `make header-stamp` | Apply header stamps, excluding `vendor` and `tests` |

Arguments can be passed to individual tools with `ARGS`:

```bash
make phpstan ARGS="--level=8"
make phpcs ARGS="--standard=PSR12"
make phpunit ARGS="--filter MyModuleTest"
make shell-tooling
make shell-phpunit
```

`make autoindex` and `make header-stamp` modify files in the module directory.
Review their changes before committing them.

The tooling and PHPUnit services mount the generated PrestaShop directory. Run
`make up` at least once for the selected version before using them.

## Persistence and Cleanup

`make down` removes the containers but preserves development data:

- The generated shop remains in `prestashop/<PS>/`.
- MySQL data remains in the project's `db_database` named volume.
- The module source remains in `module/`.
- Tooling and PHPUnit dependencies remain in `tooling/vendor/` and
  `phpunit/vendor/`.

Because each project name contains the module name and PrestaShop version, the
database volume is isolated between version environments. The module, tooling,
and PHPUnit directories are shared bind mounts.

`make down-hard` also removes the project's named volumes and the generated
`prestashop/<PS>/` directory, resetting that PrestaShop environment completely.
The module source and the dependencies in `tooling/` and `phpunit/` are not
removed.

## License

This project is licensed under the [MIT License](LICENSE).
