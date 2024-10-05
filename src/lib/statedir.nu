export const nixpkgs_input = {nixpkgs: "github:NixOS/nixpkgs/nixpkgs-unstable"}

export def get-state [statedir]: nothing -> record {
    let actual_statedir = if $statedir == "" {
        try {
            open $"($env.HOME)/.envil/current-state.txt"
        } catch {
            $"($env.HOME)/.envil"
        }
    } else {$statedir}
    mkdir $actual_statedir
    let statefile = $"($actual_statedir)/envil-state.yaml"
    try {
        open $statefile
    } catch {
        # print $"No envil state file found. Generating ($statefile)"
        let defstate = {
            inputs: $nixpkgs_input
            envs: {default: {}}
        }
        $defstate | save $statefile
        $defstate
    } | insert statedir $actual_statedir
}

export def set-state [statedir] {
    $statedir | path expand | save -f $"($env.HOME)/.envil/current-state.txt"
}
