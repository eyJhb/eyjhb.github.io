{
  pkgs ? import <nixpkgs> { },
  baseURL ? "http://127.0.0.1",
  production ? false,
  ...
}:

let
  pypreprocessor = pkgs.writers.writePython3 "preprocessor" {
    flakeIgnore = [
      "E203" # whitespace before ':'
      "W503" # line break before binary operator
    ];
  } ./scripts/preprocessor.py;
in
pkgs.stdenvNoCC.mkDerivation {
  name = "eyjhb-hugo-website";

  src = pkgs.lib.cleanSource ./.;

  nativeBuildInputs = with pkgs; [
    hugo
    plantuml
  ];

  HUGO_ENVIRONMENT = if production then "production" else "development";

  patchPhase = ''
    find content -type f -name '*.md' | ${pypreprocessor} --overwrite
  '';

  buildPhase =
    let
      minifyArg = if production then "--minify" else "";
    in
    ''
      hugo ${minifyArg} --baseURL "${baseURL}" --destination public
    '';

  installPhase = ''
    mkdir $out
    cp -a public $out
  '';
}
