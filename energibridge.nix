{
  pkgs ? import <nixpkgs> { },
}:

pkgs.rustPlatform.buildRustPackage rec  {
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

  # nativeBuildInputs = [ pkgs.libcap ];

  buildPhase = ''
    cargo build --release
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp target/release/energibridge $out/bin/
  '';

  # meta = with pkgs.lib; {
  #   description = "EnergiBridge Rust project";
  #   license = licenses.mit;
  #   maintainers = [ maintainers.anon ];
  # };
}
