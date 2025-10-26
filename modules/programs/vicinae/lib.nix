{
  pkgs,
}:
{
  mkExtension =
    {
      name,
      src,
    }:
    pkgs.buildNpmPackage {
      inherit name src;
      inherit (pkgs.importNpmLock) npmConfigHook;
      installPhase = ''
        runHook preInstall

        mkdir -p $out
        cp -r /build/.local/share/vicinae/extensions/${name}/* $out/

        runHook postInstall
      '';
      npmDeps = pkgs.importNpmLock { npmRoot = src; };
    };

  mkRayCastExtension =
    {
      name,
      src ? null,
      rev ? null,
      sha256 ? null,
    }:
    let
      resolvedSrc =
        if src != null then
          src
        else
          pkgs.fetchgit {
            inherit rev sha256;
            url = "https://github.com/raycast/extensions";
            sparseCheckout = [ "/extensions/${name}" ];
          }
          + "/extensions/${name}";
    in
    pkgs.buildNpmPackage {
      inherit name;
      inherit (pkgs.importNpmLock) npmConfigHook;
      src = resolvedSrc;
      installPhase = ''
        runHook preInstall

        mkdir -p $out
        cp -r /build/.config/raycast/extensions/${name}/* $out/

        runHook postInstall
      '';
      npmDeps = pkgs.importNpmLock { npmRoot = resolvedSrc; };
    };
}
