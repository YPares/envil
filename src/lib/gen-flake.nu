use nix-printer.nu *
use state.nu nixpkgs_input

export def or-else [defval] {
    if $in == null {$defval} else {$in}
}

def get-input-pkgs [prefix pkg_list] {
    $pkg_list | each {|p|
        if (($p | describe) == "string") {
            if ($p | str contains " ") {
                $"\(($p))"
            } else {
                $"($prefix).($p)"
            }
        } else { # $p is a record
            let attr = $p | columns | get 0
            let vals = $p | values | get 0
            (get-input-pkgs $"($prefix).($attr)" $vals)
        }
    } | flatten
}

def gen-one-env [env_name env_desc]: nothing -> record<inputs: list<string>, output: string, extends: list<string>> {
    mut env_inputs = []
    mut env_paths = []
    for i in ($env_desc.contents? | transpose name pkgs) {
        $env_inputs = $env_inputs | append $i.name
        $env_paths = $env_paths | append (get-input-pkgs $"imp.($i.name)" $i.pkgs)
    }
    for i in $env_desc.extends? {
        $env_paths = $env_paths | append $"envs.($i)"
    }
    let output = (r
        buildEnv (a
            name (s $"($env_name)-envil")
            paths (l ...$env_paths)
        )
    )
    {
        inputs: $env_inputs
        output: $output
        extends: ($env_desc.extends? | or-else [])
    }
}

# Prints the flake part for $env_name from the data obtained from envil state
export def output-flake [envname systems nixpkgs_key inputs outputs] {
    (r
     (c "This has been generated by `envil'\nDO NOT EDIT MANUALLY")
     (a
        description (s $"envil-generated flake for env ($envname)")
        inputs (rec2a $inputs)
        outputs (f inputs
            (let_
                [forEachSystem (r $"inputs.($nixpkgs_key).lib.genAttrs" $systems)]
                (a packages (r forEachSystem (f system
                    (let_
                        [imp (r (c "An attrset containing each input's packages for the current system")
                                builtins.mapAttrs
                                (f _ input
                                    "input.packages.${system} or input.legacyPackages.${system}")
                                inputs)
                         buildEnv (r (c "A function to make an environment")
                                     $"imp.($nixpkgs_key).buildEnv")
                         envs (r (c $"Each environment used by env ($envname)")
                                 (rec2a ({__current: $"envs.($envname)"} | merge $outputs)))]
                        envs))))))))
}

# Prints out the flake that will generate the <env-name> environment
export def generate-flake [
    envname: string
    state: record
    systems: list<string> = []
] {
    # We do a BFS through the existing envs to resolve the `extends',
    # and recursively generate a buildEnv target for each extended env:
    mut to_do = [$envname]
    mut already_done = {}
    mut generated_envs = {}
    while (not ($to_do | is-empty)) {
        let cur_name = $to_do | first
        $to_do = $to_do | skip 1
        let cur_env = try {
            $state.envs | get $cur_name
        } catch {
            print $"(ansi red)Env (ansi yellow)`($cur_name)'(ansi red) does not exist in statedir (ansi yellow)`($state.statedir)'(ansi reset)"
            error make {msg: $"Env `($cur_name)' not found"}
        }
        mut cur_done = gen-one-env $cur_name $cur_env
        let extends = $cur_done.extends
        $cur_done = $cur_done | reject extends
        $generated_envs = $generated_envs | insert $cur_name $cur_done
        for i in $extends {
            if (not ($i in $already_done) and not ($i in $to_do)) {
                $to_do = $to_do | append $i
            }
        }
        $already_done = $already_done | upsert $cur_name true
    }

    # Make a table with 3 columns: 'name', 'inputs' & 'output':
    let $envs_table = $generated_envs | transpose name _contents | flatten

    mut input_urls = {}
    mut input_follow_links = {}
    for i in ($envs_table | each {$in.inputs} | flatten | uniq) {
        mut url = try {
                $state.inputs | get $i
            } catch {|e|
                print $"(ansi red)Input (ansi yellow)`($i)'(ansi red) is not defined in the `inputs' section(ansi reset)"
                error make $e
            }
        if (($url | describe) | str starts-with "record") {
            # $input_url is a record `{"<url>": [followed_input0, followed_input1, ...]}'
            let actual_url = $url | columns | get 0
            for follow_link in ($url | values) {
                $input_follow_links = $input_follow_links | upsert $i {or-else {} | merge $follow_link}
            }
            $url = $actual_url
        }
        # else $input_url is already just an URL string
        $input_urls = $input_urls | insert $i $url
    }

    let nixpkgs_key = match ($input_urls | transpose key url | where {$in.url | str downcase | str starts-with "github:nixos/nixpkgs"}) {
        [] => {
            $input_urls = $input_urls | insert "nixpkgs" $nixpkgs_input.nixpkgs
            "nixpkgs"
        }
        [$i] => $i.key
        [$i ...$_rest] => $i.key
    }

    let systems = if ($systems | is-empty) {
        $"inputs.($nixpkgs_key).lib.systems.flakeExposed"
    } else {
        (l ...($systems | each {s $in}))
    }

    mut inputs = {}
    for i in ($input_urls | transpose key url) {
        $inputs = $inputs | insert $"($i.key).url" $i.url
        if ($i.key in $input_follow_links) {
            for l in ($input_follow_links | get $i.key | transpose src dest) {
                $inputs = $inputs | insert $"($i.key).inputs.($l.src).follows" (s $l.dest)
            }
        }
    }

    let $outputs = $envs_table | each {[$in.name $in.output]} | into record

    output-flake $envname $systems $nixpkgs_key $inputs $outputs |
    if ($env.NIX_FORMATTER? == null) {
        $in
    } else {
        $in | run-external $env.NIX_FORMATTER
    }
}
