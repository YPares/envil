export const nixpkgs_input = {nixpkgs: "github:NixOS/nixpkgs/nixpkgs-unstable"}

export def main [confdir]: nothing -> record {
    let actual_confdir = if $confdir == "" {
        $"($env.HOME)/.envil"
    } else {$confdir}
    mkdir $actual_confdir
    let statefile = $"($actual_confdir)/envil-state.yaml"
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
    } | insert confdir $actual_confdir
}
