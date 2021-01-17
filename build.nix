with import <nixpkgs> { };

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
