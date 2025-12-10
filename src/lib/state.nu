export const nixpkgs_input = {nixpkgs: "github:NixOS/nixpkgs/nixpkgs-unstable"}

const defstate = {
    inputs: $nixpkgs_input
    envs: {
        basic: {
            description: "Just a basic env"
            contents: {
                nixpkgs: [hello]
            }
        }
    }
}

export def envil-dir []: nothing -> path {
    if ($env.ENVIL_STACK? != null) {
        $env.ENVIL_STACK | path expand -n
    } else {
        [~ .envil] | path join | path expand -n
    }
}

def currents-path []: nothing -> path {
    mkdir (envil-dir)
    [(envil-dir) currents.nuon] | path join
}

export def with-resolved-statedir [
    unresolved_statedir: string = ""
    --on-flake-url: closure
    --on-flake-state: closure
    --on-yaml-state: closure
] {
    let statedir = if $unresolved_statedir == "" {
        try {
            open (currents-path) | get statedir
        } catch {
            print $"(ansi red)No statedir is known. Run with `-d' to use or create a statedir(ansi reset)"
            error make {msg: "No statedir"}
        }
    } else {
        $unresolved_statedir
    }
    if ($statedir | str contains ":") {
        # statedir is already a flake URL
        do $on_flake_url $statedir
    } else if ($statedir | path join "flake.nix" | path exists) {
        # statedir is a path to a local flake
        do $on_flake_state $statedir
    } else {
        # statedir is yaml
        do $on_yaml_state $statedir
    }
}

export def get-state [
    unresolved_statedir: string
    --should-exist
]: nothing -> record {
    ( with-resolved-statedir $unresolved_statedir
        --on-flake-url {|statedir|
            load-state-from-flake $statedir
        }
        --on-flake-state {|statedir|
            # We first resolve the full flake URL, because builtins.getFlake doesn't accept relative paths:
            let statedir = ^nix flake metadata $statedir --json | from json | get originalUrl
            load-state-from-flake $statedir
        }
        --on-yaml-state  {|statedir|
            load-state-from-yaml ($statedir | path expand) $should_exist
        }
    )
}

def load-state-from-flake [
    statedir: string
] {
    let packages = (
        ^nix eval --impure --json --expr
            $"with builtins; mapAttrs \(_k: pkg: pkg.name or \"no description\") \(getFlake \"($statedir)\").packages.${currentSystem}"
    ) | from json
    {
        inputs: {
            source: $statedir
        }
        envs: ($packages | columns | each {|attr|
                {
                    $attr: {
                        description: ($packages | get $attr)
                        contents: {
                            source:
                                [$attr]
                        }
                    }
                }
            } | into record)
        statedir_is_flake: true
        statedir: $statedir
    }
}

def load-state-from-yaml [
    statedir: string
    should_exist
]: nothing -> record {
    if (not ($statedir | path exists)) {
        if $should_exist {
            error make {msg: $"Dir ($statedir) does not exist"}
        } else {
            mkdir $statedir
        }
    }
    let statefile = [$statedir envil-state.yaml] | path join
    mut state = try {
        open $statefile
    } catch {
        print $"(ansi yellow)No envil-state.yaml found in the statedir. Generating `($statefile)'(ansi reset)"
        $defstate | save $statefile
        $defstate
    }

    let schema_path = [($env.CURRENT_FILE | path dirname) envil-state-schema.json] | path join
    let jv_out = ^jv $schema_path $statefile | complete
    if $jv_out.exit_code != 0 {
        print $"(ansi red)($statefile) is not a valid envil state file:(ansi reset)"
        print $"(ansi red)|(ansi reset)"
        print ($jv_out.stdout | lines | each { $"(ansi red)|(ansi reset) ($in)" } | str join (char newline))
        print ""
        error make {msg: "Failed to validate state file"}
    }
    
    let includes = $state.includes?
    for otherdir in $includes {
        # Resolve otherdir relative to current $statedir
        let otherdir = do {
            cd $statedir
            $otherdir | path expand
        }
        let other = get-state $otherdir --should-exist
        $state = {
            inputs: ($other.inputs? | or-else {} | merge ($state.inputs? | or-else {}))
            envs: ($other.envs? | or-else {} | merge ($state.envs? | or-else {}))
        }
    }
    $state | insert statedir $statedir
}

export def set-currents [
    --envstack: any = null
    --statedir: any = null
] {
    mut currents = get-currents
    if ($envstack != null) {
        $currents.envstack = $envstack
    }
    if ($statedir != null) {
        $currents.statedir = $statedir
    }
    $currents | save -f (currents-path)
}

export def get-currents [] {
    try {
        open (currents-path)
    } catch {
        {}
    } |
    upsert envstack {or-else []} |
    update envstack {upsert active {or-else true}}
}

# Compute the transitive closure of environments that <envname> extends from
export def get-extends-closure [
    envname: string
    state: record<envs: any>
]: nothing -> list<string> {
    mut result = []
    mut to_visit = [$envname]
    mut visited = {}

    while (not ($to_visit | is-empty)) {
        let current = $to_visit | first
        $to_visit = $to_visit | skip 1

        if ($current in $visited) {
            continue
        }
        $visited = $visited | upsert $current true

        let env_desc = try {
            $state.envs | get $current
        } catch {
            continue
        }

        let extends = $env_desc.extends? | default []
        $result = $result | append $extends
        $to_visit = $to_visit | append $extends
    }

    $result | uniq
}
