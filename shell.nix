{ pkgs ? import <nixpkgs> {}, ... }:

let
  currentDir = builtins.toString ./.;
  livebuilder = pkgs.writeScriptBin "livebuilder" ''
    trap 'kill $(jobs -pr)' SIGINT SIGTERM EXIT
    ${pkgs.python3Packages.livereload}/bin/livereload --target ${currentDir} --port 8080 --wait 5 ${currentDir}/result/public &
    find ${currentDir} | ${pkgs.entr}/bin/entr -s 'nix-build --out-link ${currentDir}/result --arg baseURL "http://127.0.0.1:8080/" --arg production false'
  '';
in pkgs.mkShell {
  
  packages = with pkgs; [
    # entr
    livebuilder
    # python3Packages.livereload
  ];
}
