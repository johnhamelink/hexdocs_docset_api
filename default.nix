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
    rev = "e417656a60e7646ea216588b028129f3902a096d";
    repo = "${pname}";
    sha256 = "sha256-qa+JNISgL0ZT9+DTwJlOuSDUkB3ddfZaTXnxP5OgRkc=";
  };

  mixNixDeps = with pkgs; import ./mix.nix { inherit lib beamPackages; };

  postBuild = ''
    # for external task you need a workaround for the no deps check flag
    # https://github.com/phoenixframework/phoenix/issues/2690
    mix do deps.loadpaths --no-deps-check, phx.digest
    mix phx.digest --no-deps-check
  '';
}
