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
      --replace-quiet '@@resources@@' "$out/resources" \
      --replace-quiet '@@statedir@@' '${nixStateDirectory}' \
      --replace-quiet '@@systemddir@@' "$out/lib/systemd/system" \
      --replace-quiet '@@env@@' "${nonNixosGpuEnv}"
  '';
  installPhase = ''
    mkdir -p $out/{bin,resources,lib/systemd/system}
    cp non-nixos-gpu-setup $out/bin
    cp non-nixos-gpu.service $out/lib/systemd/system
  '';
}
