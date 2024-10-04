#!/usr/bin/env nu

use lib/gen-flake.nu
use lib/get-state.nu

def path_to_url [path: path] {
    $"path:($path | path expand)"
}

def main [] {
    help main
}

# Print out the flake that will generate the <envname> environment
def "main gen-flake" [
    envname = "default" # The name of the env to generate a flake for
    --confdir (-c) = "" # Where to read the envil state from
    --systems (-s): list<string> = [] # Which systems should this flake build for.
                                      # The flake will use `nixpkgs.lib.systems.flakeExposed' if <systems> is left empty
] {
    let state = get-state $confdir
    gen-flake $envname $state $systems
}

# Start a subshell containing <envname>
def "main shell" [
    envname: string = "default" # The environment to open in a subshell
    --confdir (-c) = "" # Where to read the envil state from
] {
    let state = get-state $confdir
    gen-flake $envname $state | save -rf $"($state.confdir)/flake.nix"
    print $"Starting a subshell with env `($envname)'..."
    SHELL_ENV=$envname ^nix shell $"(path_to_url $state.confdir)#($envname)"
}

# List the available envs
def "main envs" [
    --confdir (-c) = "" # Where to read the envil state from
] {
    let state = get-state $confdir
    $state.envs | columns
}

# Print the current config of each env
def "main config" [
    --confdir (-c) = "" # Where to read the envil state from
] {
    let state = get-state $confdir
    print $"Reading config from `($state.confdir)':\n"
    print ($state | to yaml)
}

# Apply the selected environment, ie. switch the bins in
# `<confdir>/current/bin' to those of <envname>
def "main switch" [
    envname: string = "default" # The environment to switch to
    --confdir (-c) = "" # Where to read the envil state from
] {
    let state = get-state $confdir
    gen-flake $envname $state | save -rf $"($state.confdir)/flake.nix"
    print $"Building env `($envname)'..."
    ^nix build $"(path_to_url $state.confdir)#($envname)" -o $"($state.confdir)/current"
}
