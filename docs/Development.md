# Development of module

Below you can find basic guidelines and rules that must be followed during module development.

## Validate your code

```shell
  # Init project, run fmt and validate
  terraform init -reconfigure
  terraform fmt -recursive
  terraform validate

  # Lint with TFLint, calling script from https://github.com/dsb-norge/terraform-tflint-wrappers
  alias lint='curl -s https://raw.githubusercontent.com/dsb-norge/terraform-tflint-wrappers/main/tflint_linux.sh | bash -s --'
  lint

  # Validate all example directories
  for example_dir in examples/*/; do
    dir_name=${example_dir%*/}
    if ! terraform -chdir=${dir_name} init; then echo "terraform init failed in ${dir_name}"; break; fi
    if ! terraform -chdir=${dir_name} validate; then echo "terraform validate failed in ${dir_name}"; break; fi
    if ! terraform -chdir=${dir_name} fmt -check; then echo "terraform fmt check failed in ${dir_name}"; break; fi
    if ! .tflint/tflint -chdir=${dir_name} --config .tflint.hcl; then echo "tflint failed in ${dir_name}"; break; fi
  done

  # Manually test all examples
  az account set --subscription 'GUID HERE'
  for example_dir in examples/*/; do
    dir_name=${example_dir%*/}
    if ! terraform -chdir=${dir_name} init; then echo "terraform init failed in ${dir_name}"; break; fi
    if ! ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv) terraform -chdir=${dir_name} apply; then echo "terraform apply failed in ${dir_name}"; break; fi
    if ! ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv) terraform -chdir=${dir_name} destroy; then echo "terraform destroy failed in ${dir_name}"; break; fi
  done

  # Run tests using built-in terraform testing framework
  az account set --subscription 'GUID HERE'
  ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv) terraform test
```

### Naming parity and migration tests

`modules/naming` must render exactly the names `Azure/naming/azurerm` 0.4.3 did, from the same `random_string` values,
and must take over the state `Azure/naming` left behind. Callers' deployed names depend on both, and none of the named
Azure resources can be renamed.

| Test | Checks | Azure access |
| --- | --- | --- |
| `tests/unit-tests-naming.tftest.hcl` | Both modules render identical names from fixed random values (typical suffix, truncation, empty suffix element) | No |
| `tests/unit-tests-naming-migration.tftest.hcl` | `modules/naming` applied on the state `Azure/naming` created keeps every name | No |
| `tests/integration-test-07-migration-from-2.5.0.tftest.hcl` | A caller on 2.5.0 upgraded to this checkout keeps every resource: same resource IDs, private endpoint names and NAT gateway IP | Yes |

The migration tests share one state between runs of different modules with `state_key` (terraform 1.11+). The fixtures
in `tests/migration/legacy/` and `tests/migration/current/` must stay identical apart from `module.tf`.

The first two run locally without Azure:

```shell
terraform init
terraform test -filter=tests/unit-tests-naming.tftest.hcl -filter=tests/unit-tests-naming-migration.tftest.hcl
```

### Databricks in the private endpoints example

`examples/02-private-endpoints` creates an Azure Databricks workspace only so it has something to connect a private
endpoint to. The workspace sits in `westeurope`, apart from the rest of the example.

It is not in `swedencentral` with the rest: since 2026-10-06 a workspace there never finishes deleting. Something in
that region subscribes to Event Grid events on the workspace's managed storage account and re-creates the subscription
each time the delete removes it, so the delete loops for hours and ends in `ApplianceBeingDeleted`.
`integration-test-02` hits the CI job timeout.

Deleting a workspace normally takes 3–5 minutes. If test 02 hangs on its destroy again, look in the activity log of the
test subscription for a `Microsoft.Databricks/workspaces/delete` that never completes.

A run that is cancelled mid-test never destroys what it created. The resource group `rg-github-network-module-test-dbx`
has a fixed name, so the next run fails to create it until it is deleted.

## Release and versioning

This module uses [semantic versioning](https://semver.org).
Always use [conventional commits](https://www.conventionalcommits.org/en/v1.0.0/) in your pull-requests.
Module is using [release-please action](https://github.com/googleapis/release-please-action) and it create release PR based on commit message after PR is merged to main.
Use [respective conventional commits](https://github.com/googleapis/release-please?tab=readme-ov-file#how-should-i-write-my-commits) to achieve correct [SemVer](https://semver.org) release version.

Refer to [release-please documentation](https://github.com/googleapis/release-please) for better understanding and when additional questions occur.

## Dependencies and versions

The full strategy, with the reasons, is
[Module dependencies](https://github.com/dsb-norge/github-actions-terraform/blob/main/docs/Module-dependencies.md)
in github-actions-terraform. In short:

- **Providers get a range over one major**, `version = ">= 4.0.0, < 5.0.0"`, with `source` and
  `version` on lines of their own. Never pin a provider exactly: every caller of the module would be
  bound to that version.
- **No lock file.** Callers decide with their own lock file; CI here always installs the newest
  release in the range, and the weekly scheduled run tests it.
- **Modules this module calls are pinned exactly**, `version = "0.4.4"`.

What happens on its own:

- **Dependabot** proposes new versions of the called modules, never of a provider and never a
  major, as `fix(deps)` commits, so each merged bump is released as a patch.
- **The Dependabot admission** judges each of its pull requests before anything runs it (allowed
  publisher, at least three days old, signed like the version before).
- **With auto-merge switched on** in `.github/workflows/test.yaml`, an admitted, green Dependabot
  pull request that stays within each dependency's major merges itself, and so does the release
  pull request that follows; the `Create test matrix` job's notice says why one does not.

When to act:

| When | Do |
|---|---|
| A Dependabot pull request waits because it moves a 0.x module's minor or a major | Read the called module's release notes, check the tests, and merge it. If it changes what callers get, push a commit saying so (`feat:`, or `feat!:` with a `BREAKING CHANGE:` footer). |
| The weekly scheduled run is red | A provider release broke the module or its tests: fix it in a pull request (`fix:`), or cap the range below that release until it is fixed. |
| A provider's next major is out and callers are moving | Widen the range (`< 6.0.0`, a `feat:` release) when the module works with both majors, or move it (`>= 5.0.0, < 6.0.0`, a `feat!:` release) when it needs the new one. |
| The module needs a newer provider feature | Raise the floor in the same pull request, a `feat:` release. |
| A release pull request waits | It changes more than the changelog; review and merge it. |

## Documentation

Repo CI action has step to generate terraform documentation automatically using [terraform-docs action](https://github.com/terraform-docs/gh-actions) and configuration files in repo.
It is, however, possible to run ```terraform-docs``` locally to check documentation during development or when other need occur.

### Generate and inject terraform-docs in README.md

```shell
# go1.17+
go install github.com/terraform-docs/terraform-docs@v0.20.0
export PATH=$PATH:$(go env GOPATH)/bin

# root
terraform-docs .

# docs for examples
for ex_dir in $(find "./examples" -maxdepth 1 -mindepth 1 -type d | sort); do
  terraform-docs "${ex_dir}" --config ./examples/.terraform-docs.yml
done
```
