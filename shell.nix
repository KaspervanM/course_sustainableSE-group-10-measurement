{
  pkgs ? import <nixpkgs> {},
}:

let
  energibridge = pkgs.rustPlatform.buildRustPackage rec  {
  pname = "energibridge";
  version = "main";

  src = pkgs.fetchFromGitHub {
    owner = "tdurieux";
    repo = pname;
    rev = version;
    sha256 = "sha256-LGOgs0oOVZGvAuQzDMGgLItF6qahthco7RlwTaS7piI=";
  };

  cargoLock = {
    lockFile = "${src}/Cargo.lock";
  };

  buildPhase = ''
    cargo build --release
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp target/release/energibridge $out/bin/
  '';
};
in
pkgs.mkShell {
  buildInputs = [ energibridge ];

  shellHook = ''
    chmod +x setup.sh test.sh src/gen_sequence.sh src/docker_test.sh src/podman_test.sh
    ./setup.sh
    exit
  '';
}
