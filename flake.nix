{
  description = "A tool to forge custom, isolated & mergeable environments";
  
  nixConfig = {
    extra-substituters = [
      "https://cache.garnix.io"
    ];
    extra-trusted-public-keys = [
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs = inputs:
    let
      forEachSystem =
        inputs.nixpkgs.lib.genAttrs inputs.nixpkgs.lib.systems.flakeExposed;
    in {
      packages = forEachSystem (system:
        let
          imp = builtins.mapAttrs (_: input:
            input.packages.${system} or input.legacyPackages.${system}) inputs;
        in rec {
          default = envil;

          envil = imp.nixpkgs.writeShellApplication {
            name = "envil";
            runtimeInputs = with imp.nixpkgs; [nushell jsonschema nixfmt-rfc-style];
            text = ''nu -n ${./src}/envil "$@"'';
          } ;

          pkgs = imp.nixpkgs;
        });
    };
}

