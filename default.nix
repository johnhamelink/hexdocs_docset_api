with import <nixpkgs> { };
let
  packages = beam.packagesWith beam.interpreters.erlangR24;
in
packages.mixRelease rec {
  elixir = packages.elixir_1_14;
  pname = "hexdocs_docset_api";
  version = "1.0.1";

  enableDebugInfo = true;
  stripDebug = false;

  src = pkgs.fetchFromGitHub {
    owner = "hissssst";
    rev = "92c416949cd9c5ecece1f2e124003d4acb2b7287";
    repo = "${pname}";
    sha256 = "sha256-3c5B6roNLZFzR/ryFUM6ANPFh7OY/tcW8Yl4JXQDg3I=";
  };

  mixNixDeps = with pkgs; import ./mix.nix { inherit lib beamPackages; };

  postBuild = ''
    # for external task you need a workaround for the no deps check flag
    # https://github.com/phoenixframework/phoenix/issues/2690
    mix do deps.loadpaths --no-deps-check, phx.digest
    mix phx.digest --no-deps-check
  '';
}
