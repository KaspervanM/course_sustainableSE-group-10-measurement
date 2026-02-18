{
  pkgs ? import <nixpkgs> {},
}:

let
  energibridge = import ./energibridge.nix { };
in
pkgs.mkShell {
  buildInputs = [ energibridge ];

  shellHook = ''
    chmod +x setup.sh test.sh gen_sequence.sh docker_test.sh podman_test.sh
    ./setup.sh
    exit
  '';
}
