with import <nixpkgs> { };
let
  packages = beam.packagesWith beam.interpreters.erlang;
in
packages.mixRelease rec {
  elixir = packages.elixir_1_14;
  pname = "hexdocs_docset_api";
  version = "1.0.0";

  src = pkgs.fetchFromGitHub {
    owner = "hissssst";
    rev = "f8e422539a1dc3348c26dd73a17595ee9f6e2852";
    repo = "${pname}";
    sha256 = "sha256-3ffjieIzLEu6726PxAyP7Q3+oYh5+LZzSK09wIYiH/c=";
  };

  mixNixDeps = with pkgs; import ./mix.nix { inherit lib beamPackages; };
  postBuild = ''
    # for external task you need a workaround for the no deps check flag
    # https://github.com/phoenixframework/phoenix/issues/2690
    mix do deps.loadpaths --no-deps-check, phx.digest --no-deps-check
  '';
}
