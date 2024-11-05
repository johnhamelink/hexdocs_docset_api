{
  description = "Hexdocs Docset API - nix flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };

    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"

        "aarch64-darwin"
        "x86_64-darwin"
      ];

      perSystem =
        { pkgs, ... }:
        {
          packages.default = (pkgs.callPackage ./default.nix { inherit pkgs; });

          devShells.default = pkgs.mkShell {
            packages = with pkgs; [
              # For Nix
              mix2nix
              nixd
              nixfmt-rfc-style

              # For Elixir
              elixir
              elixir-ls
              fswatch # Used to re-run tests

              # For Elixir deps
              sqlite
              gnutar
            ];

          };
        };
    };
}
