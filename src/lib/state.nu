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

def currents-path []: nothing -> path {
    mkdir ([~ .envil] | path join | path expand -n)
    ([~ .envil currents.nuon] | path join | path expand -n)
}

# Reads the state from the statedir.
# Adds to this record a 'statedir' field, which contains the absolute path of the statedir
export def get-state [
    statedir: path
    --should-exist
]: nothing -> record {
    let statedir = if $statedir == "" {
        try {
            open (currents-path) | get statedir
        } catch {
            print $"(ansi red)No statedir is known. Run with `-d' to use or create a statedir(ansi reset)"
            error make {msg: "No statedir"}
        }
    } else {$statedir | path expand}
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

    try {
        let schema_path = [($env.CURRENT_FILE | path dirname) envil-state-schema.json] | path join
        ^jv $schema_path $statefile
    } catch {
        print $"(ansi red)($statefile) is not a valid envil state file. See validator errors above(ansi reset)"
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
    } | upsert envstack {or-else []}
}
