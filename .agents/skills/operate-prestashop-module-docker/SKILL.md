---
name: operate-prestashop-module-docker
description: Operate and evolve the Docker-based PrestaShop module development project through its Makefile. Use when configuring or starting PrestaShop versions, managing environments, working on the mutable module in module/, running Composer or the PrestaShop console, installing or uninstalling the module, running or changing PHPUnit and quality tooling, diagnosing containers, changing Docker images or services, extending Make targets, or resetting an environment.
---

# Operate PrestaShop Module Docker

## Use the repository as the source of truth

Treat the entire project as mutable. Do not assume that the sample module, PHP versions, PHPUnit version, tools, services, paths, or Make targets still match the initial repository defaults.

Before acting:

1. Work from the repository root containing `Makefile` and `compose.yml`.
2. Read the current `Makefile`, `compose.yml`, `.env.dist`, and relevant sections of `README.md`.
3. Inspect `.env`, `.env.<PS>`, `.env.<PS>.local`, and `compose.override.yaml` or `compose.override.yml` when present. These ignored files can change effective behavior. Do not expose secrets from them.
4. Inspect the relevant files under `.docker/`, `module/`, `tooling/`, and `phpunit/` when the task depends on their current implementation.
5. Check the worktree before commands that can modify host files. Preserve unrelated user changes.

Use the README as an introduction, not as stronger evidence than executable configuration. Resolve discrepancies in favor of the current Makefile, Compose configuration, Dockerfiles, entrypoints, package manifests, and lock files. Update documentation when intentionally changing public behavior.

## Understand the project structure

Use this structure as the current conceptual model, then verify it against the repository:

| Path | Responsibility |
| --- | --- |
| `.docker/` | Dockerfiles, image configuration, entrypoints, and container helper scripts |
| `module/` | The module workspace shared across PrestaShop environments; its initial `MyModule` contents are examples |
| `prestashop/<PS>/` | Generated, persistent PrestaShop installation for one image tag |
| `tooling/` | Mutable Composer project and configuration for quality or maintenance tools |
| `phpunit/` | Mutable Composer project and configuration for the test runner |
| `compose.yml` | Services, profiles, networks, volumes, mounts, and build arguments |
| `Makefile` | Main user and agent interface for environment operations |
| `.env.dist` | Committed configuration example, not effective local configuration |

Treat all initial `MyModule` contents under `module/` and `MODULE_NAME=mymodule` as starter examples. This includes the module implementation, Composer manifest and lock file, autoloading, tests, PHPUnit suite, PHPStan, PHPCS, PHP CS Fixer, Header Stamp, namespaces, compatibility constraints, exclusions, and bootstrap choices. Discover the actual module and its technical name from the current source and effective configuration. Replace or adapt the examples to the real module; never infer permanent project requirements from them.

Keep module configuration separate from infrastructure dependencies. The Composer manifests and lock files under `tooling/` and `phpunit/` define the currently installed quality tools and test runner, but they are also mutable. Add, remove, upgrade, or downgrade those dependencies according to the developer's required tools and the PHP and PrestaShop compatibility matrix. Do not treat their initial package set or versions as fixed constraints.

In the baseline architecture, the same host `module/` directory is bind-mounted into every selected PrestaShop installation. Each PrestaShop version has a separate generated installation and a project-scoped database volume. Tooling and PHPUnit use their own container profiles and persistent host-side dependency directories. Re-read `compose.yml` before relying on this model because the architecture can be extended.

## Prefer the Makefile interface

Use Make targets for normal project operations instead of calling `docker compose` directly. The Makefile currently handles environment-file layering, host UID/GID, Compose profiles, project names, and common command arguments.

Use direct Docker Compose commands only when diagnosing or developing infrastructure that the current Makefile cannot express. If an operation becomes part of the supported workflow, expose it through a documented Make target rather than leaving a repeated raw Compose command.

Determine available targets from the current Makefile. The baseline interface includes:

| Purpose | Targets |
| --- | --- |
| Lifecycle | `build`, `up`, `down`, `down-hard`, `logs`, `ps` |
| Application access | `shell`, `console` |
| Module management | `composer`, `install`, `uninstall` |
| Quality and tests | `phpstan`, `phpcs`, `cs-check`, `phpunit`, `tests`, `qa` |
| Maintenance | `autoindex`, `header-stamp` |
| Tool access | `shell-tooling`, `shell-phpunit`, `shell-tests` |

Pass target-specific arguments through `ARGS` when supported:

```bash
make PS=8.1 MODULE_NAME=example phpunit ARGS="--filter ExampleTest"
```

Do not assume `make help` works without configuration. The current Makefile validates `MODULE_NAME` before executing any target, including `help`.

## Resolve configuration and environment identity

Verify precedence in the current Makefile. The baseline order is:

1. `.env`
2. `.env.<PS>`
3. `.env.<PS>.local`
4. Variables passed on the Make command line

Command-line values have the highest Make precedence. Keep the selected `PS` stable while loading version-specific files; do not try to redefine it inside a selected version file.

The baseline Compose project name is `<MODULE_NAME>-<PS>`, with dots in `PS` replaced by hyphens. This identity selects the containers, network, and database volume. Always repeat the same `PS` and `MODULE_NAME` when inspecting, operating, or stopping an environment.

When changing the HTTP port, inspect whether `PS_DOMAIN` is explicitly configured. Update both `PS_HTTP_PORT` and `PS_DOMAIN` when necessary so generated links and the installed shop use the same address. Check that selected host ports are available before starting concurrent environments.

Treat values interpolated into shell commands, paths, Compose project names, and `ARGS` as trusted configuration only. Reject unexpected path separators, `..`, whitespace, shell metacharacters, or option injection before using generated or externally supplied values, especially for destructive operations.

## Operate an environment

Follow this sequence and adapt it to the current targets:

1. Identify the actual `MODULE_NAME`, requested `PS`, database image, ports, domain, and test PHP version from effective configuration.
2. If local configuration is missing and setup is requested, create it from `.env.dist`, then adapt it to the actual module instead of retaining sample values blindly.
3. Check prerequisites with `docker version`, `docker compose version`, and `make --version` when environment readiness is uncertain.
4. Inspect the selected environment with `make PS=<tag> MODULE_NAME=<name> ps` before changing its lifecycle.
5. Start it with `make PS=<tag> MODULE_NAME=<name> up`.
6. Confirm container status and use the URLs printed by the target. Diagnose failures through `make ... logs ARGS="<service>"`.
7. Use `shell`, `console`, `composer`, `install`, or `uninstall` as required by the task.
8. Stop while preserving data with `make ... down`.

Account for initial image pulls, builds, shop installation, and dependency installation taking longer than later runs. Remember that `logs` follows output until interrupted.

## Run quality tools and tests

Inspect the current tool manifests, lock files, Dockerfiles, entrypoints, and module configuration before selecting commands or PHP versions. Never encode a package or PHP compatibility constraint from the starter project as a permanent project rule.

Distinguish the PHPUnit runner from the module test suite:

- `phpunit/` owns the runner dependencies used by the PHPUnit container.
- `module/phpunit.xml`, `module/phpunit.xml.dist`, module bootstrap files, and `module/tests/` own the real module suite when present; the initial files are only examples.
- The PHPUnit service is opt-in. Normal PrestaShop development does not start or execute it unless a PHPUnit, tests, QA, or PHPUnit-shell target selects its profile.
- Select a test PHP version compatible with both the installed PHPUnit runner and every application file loaded by the suite. A standalone unit suite may not share the selected PrestaShop runtime requirements, while a suite that bootstraps PrestaShop must satisfy them.

Run `make up` at least once for the selected version when tools depend on the generated PrestaShop tree. Then use the narrowest applicable target, followed by `make qa` when a complete suite is useful. Pass tool-specific options through `ARGS` on individual targets; verify whether aggregate targets preserve or override `ARGS`.

Expect first runs to create or update ignored dependency directories such as `tooling/vendor/` and `phpunit/vendor/`. After changing a Composer manifest, lock file, or container PHP version, inspect the relevant entrypoint: an entrypoint that installs only when `vendor/` is absent will not refresh persistent dependencies. Ensure the dependency directory is reinstalled from the current lock file before validating the change. If dependency resolution fails, derive PHP extension and version requirements from the current Composer manifests and lock files, then adjust the relevant image or dependency set rather than applying historical assumptions.

After `composer`, `autoindex`, `header-stamp`, or any tool capable of rewriting the module, inspect the host-side Git diff and report the resulting changes. These operations do not require additional confirmation when they are necessary for the requested task.

## Evolve the infrastructure

Allow the developer to replace PHPUnit, change PHP versions, add or remove tooling, install extensions, alter services, and extend any project directory.

When changing infrastructure:

1. Inspect the complete current path from Make target to Compose service, Dockerfile, entrypoint, package manifest, lock file, mounts, and networks.
2. Make the smallest coherent change across that path.
3. Keep normal operations available through the Makefile. Add or update targets when introducing a reusable capability.
4. Keep `make help`, `.env.dist`, and `README.md` aligned with user-facing targets, variables, prerequisites, persistence, and behavior.
5. Rebuild the affected image or profile. Add a suitable Make target if the existing interface cannot rebuild it reliably.
6. Execute the changed workflow in its container and run relevant checks.
7. Inspect generated files and the Git diff; do not overwrite unrelated worktree changes.

Do not preserve outdated compatibility merely because it appeared in the starter configuration. Preserve compatibility only when required by actual consumers, persisted environments, or an explicit request.

## Handle persistence and destructive reset

Distinguish these operations clearly:

- `down` removes the selected environment's containers and network while preserving its generated shop, database volume, module source, and host-side tool dependencies under the baseline configuration.
- `down-hard` removes the selected environment's containers and volumes and deletes its generated `prestashop/<PS>/` installation under the baseline configuration.

Before every `down-hard` execution:

1. Validate `PS` and `MODULE_NAME` as safe identifiers.
2. Derive the actual Compose project name, affected volumes, and generated installation path from current configuration.
3. Tell the user exactly what will be deleted and what will remain.
4. Request explicit confirmation.
5. Execute only after receiving confirmation.

Do not infer confirmation from an earlier unrelated request. Re-read the target before execution if the Makefile has changed.

## Diagnose systematically

Check these causes before improvising fixes:

- Wrong environment selected because `PS` or `MODULE_NAME` differs between commands.
- Local `.env.*` or Compose override changing ports, versions, mounts, or services.
- Port collision between concurrently running versions.
- Explicit `PS_DOMAIN` not matching `PS_HTTP_PORT`.
- Missing generated PrestaShop files because `up` has never completed for the selected version.
- Stale host-mounted dependencies after changing PHP or a lock file.
- Missing PHP extensions or incompatible package constraints in the current manifests.
- Bind-mount ownership mismatch between host and container users.
- Tool or test network not connected to a service required by integration tests.
- An existing target rebuilding only one profile after another image definition changed.

Base conclusions on current command output and configuration. Fix reusable workflow gaps in the project rather than relying on undocumented one-off commands.

## Report outcomes

At completion, report:

- The selected module, PrestaShop tag, and Compose project when an environment was operated.
- Commands executed and resulting service or test status.
- Persistent or generated state created, retained, or removed.
- Source and infrastructure files changed.
- Any checks not run and the concrete reason.
