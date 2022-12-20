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
    rev = "558d34ea5581668049cc7eef3693646df52b15a4";
    repo = "${pname}";
    sha256 = "sha256-jryV2qjjS9ybkRVLBCUTMPBzQuLMvpvp4Mqln6DzbjY=";
  };

  mixNixDeps = with pkgs; import ./mix.nix { inherit lib beamPackages; };
  postBuild = ''
    # for external task you need a workaround for the no deps check flag
    # https://github.com/phoenixframework/phoenix/issues/2690
    mix do deps.loadpaths --no-deps-check, phx.digest --no-deps-check
  '';
}
