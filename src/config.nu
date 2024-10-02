def default_config [] {
    let envil = $"($env.HOME)/.envil"
    {
        envil_dir: $envil
        bin_dir: $"($envil)/bin"
        flakes_dir: $"($envil)/flakes"
    }
}

export def get_config [mb_path] {
    let cfg_file = if $mb_path == null {
        [$"($env.HOME)" ".envil" "config.nuon"] | path join
    } else { $mb_path }

    if ($cfg_file | path exists) {
        open $cfg_file
    } else {
        print $"Writing default config to ($cfg_file)"
        let cfg = default_config
        $cfg | save $cfg_file
        $cfg
    }
}
