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
    rev = "4d2b257f8a7f3af814de78eb4c39a39114f721b8";
    repo = "${pname}";
    sha256 = "sha256-RnrOlwy47sWokBJNWeT4uDLZn4802ycGoRaV2wcEcuI=";
  };

  mixNixDeps = with pkgs; import ./mix.nix { inherit lib beamPackages; };
  postBuild = ''
    # for external task you need a workaround for the no deps check flag
    # https://github.com/phoenixframework/phoenix/issues/2690
    mix do deps.loadpaths --no-deps-check, phx.digest --no-deps-check
  '';
}
