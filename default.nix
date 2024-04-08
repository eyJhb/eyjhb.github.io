{ pkgs ? import <nixpkgs> {}, baseURL ? "http://127.0.0.1" , ... }:

let
  pypreprocessor = pkgs.writers.writePython3 "preprocessor" {} (
    builtins.readFile ./scripts/preprocessor.py);
in pkgs.stdenvNoCC.mkDerivation {
  name = "eyjhb-hugo-website";

  src = pkgs.lib.cleanSource ./.;
  # src = ./.;

  nativeBuildInputs = with pkgs; [
    hugo
    plantuml
  ];

  HUGO_ENVIRONMENT = "production";

  patchPhase = ''
    find content -type f -name '*.md' | ${pypreprocessor} --overwrite
  '';

  buildPhase = ''
    hugo --minify --baseURL "${baseURL}" --destination public
  '';

  installPhase = ''
    mkdir $out
    cp -a public $out
  '';
}
  
