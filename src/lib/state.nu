use nix-printer.nu *

export const nixpkgs_input = a nixpkgs (a url "github:NixOS/nixpkgs/nixpkgs-unstable")

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
    let statefile = [$statedir envil.nix] | path join
    if (not ($statefile | path exists)) {
        print $"No envil.nix file found. Generating ($statefile)"
        (a
            inputs $nixpkgs_input
            envs (f "{self, nixpkgs, ...}"
                    (with nixpkgs
                        (a basic
                            (a contents (l hello)
                               description "Some environment"))))
        ) | save $statefile
    }
    let res = (^nix eval --json --expr
        (with (r import $statefile)
            (a inputs inputs
               envs (r envs ))))
    {
        statedir: $statedir
        inputs: $res.inputs
        envs: $res.envs
    }
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
