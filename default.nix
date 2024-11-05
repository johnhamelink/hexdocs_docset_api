{ pkgs ? <nixpkgs> }:
let
  packages = pkgs.beam.packagesWith pkgs.beam.interpreters.erlang_27;
in
packages.mixRelease rec {
  elixir = packages.elixir_1_17;
  pname = "hexdocs_docset_api";
  version = builtins.readFile ./VERSION;

  enableDebugInfo = true;
  stripDebug = false;

  src = pkgs.fetchFromGitHub {
    owner = "johnhamelink";
    rev = "509316f9bf9570c6b2c8e1e25b980b7276e7c4ea";
    repo = "${pname}";
    sha256 = "sha256-ttXZP/v84rK2B7Fwdy3EedhmsyFmjN3dmKNPKNNzNBI=";
  };

  mixNixDeps = with pkgs; import ./mix.nix { inherit lib beamPackages; };

  postBuild = ''
    # for external task you need a workaround for the no deps check flag
    # https://github.com/phoenixframework/phoenix/issues/2690
    mix do deps.loadpaths --no-deps-check, phx.digest
    mix phx.digest --no-deps-check
  '';
}
