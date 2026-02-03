{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  iconEntries,
  rev,
  hash,
  rootIconPath,
}:
stdenvNoCC.mkDerivation {
  pname = "material-icons-subset";
  version = "4.0.0-unstable-2026-01-29";

  src = fetchFromGitHub {
    owner = "google";
    repo = "material-design-icons";
    inherit rev hash;
    sparseCheckout = lib.unique (lib.mapAttrsToList (_: iconCfg: iconCfg.path) iconEntries);
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
