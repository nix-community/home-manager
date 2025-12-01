{
  lib,
  stdenv,
  nixStateDirectory,
  nonNixosGpuEnv,
}:

stdenv.mkDerivation {
  name = "non-nixos-gpu";

  meta = {
    description = "GPU driver setup for Nix on non-NixOS Linux systems";
    homepage = "https://github.com/exzombie/non-nixos-gpu";
    license = lib.licenses.mit;
    mainProgram = "non-nixos-gpu-setup";
  };

  src = ./.;
  patchPhase = ''
    substituteInPlace non-nixos-gpu* \
      --replace '@@resources@@' "$out/resources" \
      --replace '@@statedir@@' '${nixStateDirectory}' \
      --replace '@@env@@' "${nonNixosGpuEnv}"
  '';
  installPhase = ''
    mkdir -p $out/{bin,resources}
    cp non-nixos-gpu-setup $out/bin
    cp non-nixos-gpu.service $out/resources
  '';
}
