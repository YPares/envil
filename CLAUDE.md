# CLAUDE.md

This file provides guidance to AI agents when working with code in this repository.

## Project Overview

`envil` is a Nix-based environment management tool written in Nushell that manages environment "stacks" - composable, isolated toolkits of executables. It bridges Nix's power with YAML simplicity, allowing non-Nix users to benefit from reproducible environments while supporting Nix flakes directly.

**Key concept**: Environments are managed as a _stack_. Multiple environments can be activated simultaneously, and they can extend/include one another.

## Architecture

### Core Components

- **src/envil**: Main CLI entrypoint with all subcommands (shell, push, pop, switch, toggle, show, update, etc.)
- **src/lib/state.nu**: State management - handles loading/saving environment configurations from yaml statedirs or flake statedirs, manages the "currents" (current stack state stored in `~/.envil/currents.nuon`)
- **src/lib/gen-flake.nu**: Flake generation logic - converts yaml environment definitions into Nix flakes with proper `buildEnv` calls
- **src/lib/nix-printer.nu**: DSL for generating Nix expressions from Nushell (functions like `r`, `a`, `f`, `s`, `l` for records, attrs, functions, strings, lists)
- **src/envil-state-schema.json**: JSON Schema validating `envil-state.yaml` files (uses `jsonschema` CLI tool)

### Statedir Types

1. **Yaml statedir**: Contains `envil-state.yaml`. `envil` generates a `flakes/` subfolder with individual `flake.nix` + `flake.lock` per environment
2. **Flake statedir**: Contains `flake.nix`. `envil` treats `packages.<system>.*` attributes as environments (read-only mode)
3. **Remote flake URL**: Directly usable as statedir (e.g., `github:user/repo`)

If both files exist in a directory, the flake takes precedence.

### Environment Resolution

Environments support `extends` to inherit from other environments. The flake generator (gen-flake.nu) performs BFS traversal to resolve dependencies and generate nested `buildEnv` calls for all extended environments.

## Development Commands

### Running envil Locally

```nu
# Run envil from the repository (but you'll need to have pre-installed the flake-packaged deps)
nu src/envil <subcommand>

# Or use nix run (better)
nix run ".#envil" -- <subcommand>
```

### Testing with Example Statedir

```nu
# Use the example statedir to test functionality
nix run ".#envil" -- shell -d examples/statedir
nix run ".#envil" -- push -d examples/statedir
```

### Linting & Formatting

The flake includes `nixfmt-rfc-style` for formatting generated Nix code (applied automatically in gen-flake.nu:154).

## Key Implementation Details

### State Management (`~/.envil/`)

- `~/.envil/currents.nuon`: Stores the current environment stack and active statedir
- `~/.envil/current/`: Nix profile managed by `nix-env` containing binaries of active environments
- Stack operations (`push`, `pop`, `toggle`) modify both the profile and the currents file atomically

### Nix Integration

- Uses `nix-env` (not `nix profile`) for stack management because `--remove-all` flag availability
- Flakes are generated with `builtins.getFlake` for loading inputs
- Garbage collection: old generations are kept with `--delete-generations '+5'`
- Binary caching supported via `cachix push` or `nix copy`

### Subshells

- `envil shell` uses `nix shell` to create temporary environments
- Exports `$SHELL_ENV` variable for prompt integration
- Supports `--isolated` mode (standard UNIX paths only) and `--no-stack` (hide current stack)
- Nested subshells are explicitly not supported (checked at runtime)

### YAML Schema Validation

On every yaml statedir load, `jv` (jsonschema CLI) validates against `envil-state-schema.json`. Invalid files cause immediate errors with detailed output.

## Common Patterns

### Adding a New Subcommand

1. Add `def "main <subcommand>"` in `src/envil`
2. Follow the pattern of existing commands for state loading (`get-state $statedir`)
3. Use `select-envs` for interactive environment selection with the `--verb` parameter
4. Call `set-currents` to persist stack/statedir changes
5. Use `do-switch` or `do-remove` for Nix profile modifications

### Working with Nix Expressions

Use the DSL in `nix-printer.nu`:
- `r <expr> ...`: record/function call
- `a <key> <val> ...`: attribute set
- `f <args> <body>`: lambda function
- `s <string>`: string literal
- `l ...items`: list
- `rec2a <record>`: convert Nushell record to Nix attrset

### Handling Follow Links

Input "follows" (forcing inputs to share dependencies) are represented as nested records in yaml:
```yaml
inputs:
  myinput:
    "github:user/repo":
      nixpkgs: pkgs  # follow link: myinput's nixpkgs follows our 'pkgs' input
```

Parsed in gen-flake.nu:115-122 into `inputs.<name>.inputs.<src>.follows` Nix syntax.

## Updating envil

Users update with: `nix profile upgrade envil --refresh`

The flake uses garnix.io for CI/binary cache (see README badge and `nixConfig` in flake.nix).
