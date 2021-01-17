with import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/5d9a3e2e5a05b979d3953eeeb1a8282b241a1f53.tar.gz";
    sha256 = "0j5q1gzciz43lsz6vh28bfp1msway91s1r4vjsnkk422a9zz1qsa";
  }) {};

let jekyll_env = bundlerEnv rec {
    name = "jekyll_env";
    inherit ruby;
    gemfile = ./Gemfile;
    lockfile = ./Gemfile.lock;
    gemset = ./gemset.nix;
  };
in stdenv.mkDerivation rec {
  name = "personalblog";
  buildInputs = [ jekyll_env bundler ruby ];
  src = ./.;

  installPhase = ''
    export JEKYLL_ENV=production
    ${jekyll_env}/bin/jekyll build --destination $out
  '';
}
