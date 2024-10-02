def pexists [...dir: path] {
  $dir | path join | path exists
}

export def detect_project_type [dir: path] {
  if        (pexists $dir "devenv.nix")       { "devenv"
  } else if (pexists $dir "devbox.json")      { "devbox"
  } else if (pexists $dir "flake.json")       { "flake"
  } else if (pexists $dir "requirements.txt") { "python-reqs"
  } else if (pexists $dir "pyproject.toml")   { "poetry"
  }
}
