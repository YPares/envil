export const nixpkgs_input = {nixpkgs: "github:NixOS/nixpkgs/nixpkgs-unstable"}

export def get-state [statedir]: nothing -> record {
    let statedir = if $statedir == "" {
        try {
            open ([$env.HOME .envil current-state.txt] | path join)
        } catch {
            [$env.HOME .envil] | path join
        }
    } else {$statedir}
    mkdir $statedir
    let statefile = [$statedir envil-state.yaml] | path join
    try {
        open $statefile
    } catch {
        # print $"No envil state file found. Generating ($statefile)"
        let defstate = {
            inputs: $nixpkgs_input
            envs: {basic: {}}
        }
        $defstate | save $statefile
        $defstate
    } | insert statedir $statedir
}

export def set-statedir [statedir] {
    $statedir | path expand | save -f ([$env.HOME .envil current-state.txt] | path join)
}
