use src/config.nu *
use src/detect.nu *

def main [] {
    default_config
}

def "main add env" [
        dir: path
        --config-file (-c)=null
    ] {
    let cfg = get_config $config_file
    match (detect_project_type $dir) {
        "devenv" => {}
        "devbox" => {}
        "flake" => {}
        "python-reqs" => {}
        "poetry" => {}
    }
}
