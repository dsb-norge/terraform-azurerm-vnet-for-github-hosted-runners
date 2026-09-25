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

## Release and versioning

This module uses [semantic versioning](https://semver.org).
Always use [conventional commits](https://www.conventionalcommits.org/en/v1.0.0/) in your pull-requests.
Module is using [release-please action](https://github.com/googleapis/release-please-action) and it create release PR based on commit message after PR is merged to main.
Use [respective conventional commits](https://github.com/googleapis/release-please?tab=readme-ov-file#how-should-i-write-my-commits) to achieve correct [SemVer](https://semver.org) release version.

Refer to [release-please documentation](https://github.com/googleapis/release-please) for better understanding and when additional questions occur.

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
