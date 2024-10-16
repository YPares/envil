{
  description = "A tool to forge custom, isolated & mergeable environments";
  
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
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
            runtimeInputs = with imp.nixpkgs; [nushell jsonschema nixfmt-classic];
            text = ''nu -n ${./src}/envil "$@"'';
          } ;
        });
    };
}

