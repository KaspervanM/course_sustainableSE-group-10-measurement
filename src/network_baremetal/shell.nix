{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  name = "stress-test-env";

  buildInputs = with pkgs; [
    go 
    curl
    jq
  ];
}
