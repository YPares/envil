export const nixpkgs_input = {nixpkgs: "github:NixOS/nixpkgs/nixpkgs-unstable"}

export def get-state [statedir --should-exist]: nothing -> record {
    let statedir = if $statedir == "" {
        try {
            open ([$env.HOME .envil current-state.txt] | path join)
        } catch {
            [$env.HOME .envil] | path join
        }
    } else {$statedir}
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

export def set-statedir [statedir] {
    $statedir | path expand | save -f ([$env.HOME .envil current-state.txt] | path join)
}
