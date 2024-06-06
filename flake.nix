{
  description = "DBCaml is a database library for OCaml";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    riot = {
      url = "github:emilpriver/riot";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    bytestring = {
      url = "github:riot-ml/bytestring";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    atacama = {
      url = "github:suri-framework/atacama";
    };
    serde = {
      url = "github:serde-ml/serde";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ flake-parts, nixpkgs, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
      perSystem = { config, self', inputs', pkgs, system, ... }:
        let
          pkgs = nixpkgs.legacyPackages."${system}".extend (self: super: {
            ocamlPackages = super.ocaml-ng.ocamlPackages_5_1;
          });
          inherit (pkgs) ocamlPackages mkShell;
          inherit (ocamlPackages) buildDunePackage;
          version = "0.0.2+dev";
        in
        {
          devShells = {
            default = mkShell {
              buildInputs = [
                pkgs.opam
                ocamlPackages.dune_3
                ocamlPackages.ocaml
                ocamlPackages.utop
                ocamlPackages.ocamlformat
              ];
              inputsFrom = [
              ];
              packages = builtins.attrValues {
                inherit (pkgs) clang_17 clang-tools_17 pkg-config;
                inherit (ocamlPackages) ocaml-lsp ocamlformat-rpc-lib;
              };
              dontDetectOcamlConflicts = true;
            };
          };
          packages = {};
          formatter = pkgs.nixpkgs-fmt;
        };
    };
}

