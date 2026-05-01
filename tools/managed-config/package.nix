{
  lib,
  rustPlatform,
}:
rustPlatform.buildRustPackage {
  pname = "hermesix";
  version = "0.1.0";

  src = lib.cleanSource ./.;

  cargoLock.lockFile = ./Cargo.lock;

  postInstall = ''
    ln -s hermesix "$out/bin/hm-managed-config"
    ln -s hermesix "$out/bin/obs-studio-sync"
    ln -s hermesix "$out/bin/obs-studio-export-to-nix"
  '';

  meta = {
    description = "Home Manager managed configuration utilities";
    homepage = "https://codeberg.org/caniko/hermesix";
    mainProgram = "hermesix";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
}
