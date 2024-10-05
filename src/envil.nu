#!/usr/bin/env nu

use lib/gen-flake.nu
use lib/statedir.nu *

def path_to_url [path: path] {
    $"path:($path | path expand)"
}

def main [] {
    help main
}

# Print out the flake that will generate the <envname> environment
def "main gen-flake" [
    envname = "default" # The name of the env to generate a flake for
    --statedir (-d) = "" # Where to read the envil state from
    --systems (-s): list<string> = []
    # Which systems should this flake build for. The flake will use `nixpkgs.lib.systems.flakeExposed' if <systems> is left empty
] {
    let state = get-state $statedir
    gen-flake $envname $state $systems
}

# Start a subshell containing <envname>
def "main shell" [
    envname: string = "default" # The environment to open in a subshell
    --statedir (-d) = "" # Where to read the envil state from and write temporary flake.nix
] {
    let state = get-state $statedir
    gen-flake $envname $state | save -rf $"($state.statedir)/flake.nix"
    print $"(ansi grey)Starting a subshell with env (ansi yellow)`($envname)'(ansi grey)...(ansi reset)"
    SHELL_ENV=$envname ^nix shell $"(path_to_url $state.statedir)#($envname)"
}

# List the available envs
def "main envs" [
    --statedir (-d) = "" # Where to read the envil state from
] {
    let state = get-state $statedir
    print $"(ansi grey)Envs defined in statedir (ansi yellow)`($state.statedir)'(ansi grey):(ansi reset)"
    $state.envs | columns
}

# Print the current config of each env
def "main state" [
    --statedir (-d) = "" # Where to read the envil state from
] {
    let state = get-state $statedir
    print $"(ansi grey)Current state dir is (ansi yellow)`($state.statedir)'(ansi grey):\n"
    print $"(ansi green)($state | reject statedir | to yaml)(ansi reset)"
}

# Set the default envil statedir to <statedir>
def "main set-statedir" [
    statedir # A directory meant to contain an `envil-state.yaml' file
] {
    set-state $statedir
    print $"(ansi grey)Default state dir set to (ansi yellow)`($statedir)'(ansi reset)"
}

# Apply the selected environment, ie. switch the bins in `<statedir>/current/bin' to those of <envname>
def "main switch" [
    envname: string = "default" # The environment to switch to
    --statedir (-d) = "" # Where to read the envil state from and write temporary flake.nix
] {
    let state = get-state $statedir
    gen-flake $envname $state | save -rf $"($state.statedir)/flake.nix"
    print $"(ansi grey)Building env (ansi yellow)`($envname)'(ansi grey)...(ansi reset)"
    ^nix build $"(path_to_url $state.statedir)#($envname)" -o $"($state.statedir)/current"
}
