{
  pkgs ? import <nixpkgs> {
    config.allowUnfree = true;
  },
}:

let
  energibridge = import ./energibridge.nix { };
in
pkgs.mkShell {
  buildInputs =
    (with pkgs;
    [
      vagrant
      ansible
    ])
    ++ [ energibridge ];

  shellHook = ''
    ansible-galaxy collection install community.general
    chmod +x setup.sh test.sh test_baremetal.sh gen_sequence.sh docker_test.sh podman_test.sh
    ./setup.sh
    exit
  '';
}
