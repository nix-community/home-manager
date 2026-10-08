{
  pkgs,
}:
let
  buildExtension =
    {
      name,
      src,
      installPhase,
      npmDepsHash,
    }:
    pkgs.buildNpmPackage (
      {
        inherit name src installPhase;
      }
      // (
        if npmDepsHash != null then
          { inherit npmDepsHash; }
        else
          {
            inherit (pkgs.importNpmLock) npmConfigHook;
            npmDeps = pkgs.importNpmLock { npmRoot = src; };
          }
      )
    );
in
{
  mkExtension =
    {
      name,
      src,
      npmDepsHash ? null,
    }:
    buildExtension {
      inherit name src npmDepsHash;
      installPhase = ''
        runHook preInstall

        mkdir -p $out
        cp -r /build/.local/share/vicinae/extensions/${name}/* $out/

        runHook postInstall
      '';
    };

  mkRayCastExtension =
    {
      name,
      src ? null,
      rev ? null,
      sha256 ? null,
      npmDepsHash ? null,
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
    buildExtension {
      inherit name npmDepsHash;
      src = resolvedSrc;
      installPhase = ''
        runHook preInstall

        mkdir -p $out
        cp -r /build/.config/raycast/extensions/${name}/* $out/

        runHook postInstall
      '';
    };
}
