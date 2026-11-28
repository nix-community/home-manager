{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  rev,
  hash,
  rootIconPath,
  iconEntries,
}:
let
  sparseCheckout = lib.unique (lib.mapAttrsToList (_: iconCfg: iconCfg.path) iconEntries);
  sparseHash = builtins.substring 0 8 (
    builtins.hashString "sha256" (lib.concatStringsSep "\n" ([ rev ] ++ sparseCheckout))
  );
in
stdenvNoCC.mkDerivation {
  pname = "material-icons-subset";
  version = "4.0.0-unstable-2026-01-29";

  src = fetchFromGitHub {
    name = "material-design-icons-${sparseHash}";
    owner = "google";
    repo = "material-design-icons";
    inherit rev hash sparseCheckout;
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    ${lib.concatStringsSep " " (
      lib.mapAttrsToList (
        destinationPath: iconCfg:
        let
          finalPath = "$out/${rootIconPath}/${destinationPath}";
        in
        ''
          install -Dm644 "${iconCfg.path}" "${finalPath}"
          ${lib.optionalString (iconCfg.color != null) ''
            sed -i 's/<svg /<svg fill="${iconCfg.color}" /' "${finalPath}"
          ''}
        ''
      ) iconEntries
    )}

    runHook postInstall
  '';
}
