export const nixpkgs_input = {nixpkgs: "github:NixOS/nixpkgs/nixpkgs-unstable"}

def currents-path [] {
    ([$env.HOME .envil currents.nuon] | path join)
}

# Reads the state from the statedir.
# Adds to this record a 'statedir' field, which contains the absolute path of the statedir
export def get-state [statedir --should-exist]: nothing -> record {
    let statedir = if $statedir == "" {
        try {
            open (currents-path) | get statedir
        } catch {
            print $"(ansi red)No statedir is known. First use a command with `-d' to use or create a statedir(ansi reset)"
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
        # print $"No envil state file found. Generating ($statefile)"
        let defstate = {
            inputs: $nixpkgs_input
            envs: {basic: {}}
        }
        $defstate | save $statefile
        $defstate
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
    --envname = null
    --statedir = null
] {
    mut currents = get-currents
    if ($envname != null) {
        $currents.env = $envname
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
    }
}

export def erase-current-env [] {
    get-currents | collect | reject env | save -f (currents-path)
}
