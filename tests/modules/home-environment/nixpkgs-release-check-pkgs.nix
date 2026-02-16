{ lib, ... }:
let
  releaseInfo = lib.importJSON ../../../release.json;
  hmRelease = releaseInfo.release;
  pkgsRelease = "<invalid>";
in
{
  test.asserts.warnings.expected = [
    ''
      You are using

        Home Manager version: ${hmRelease}
        Nixpkgs version used to evaluate Home Manager: ${hmRelease}
        Nixpkgs version used for packages (`pkgs`): ${pkgsRelease}

      Using mismatched versions is likely to cause errors and unexpected
      behavior. It is therefore highly recommended to use a release of Home
      Manager that corresponds with your chosen release of Nixpkgs.

      If you insist then you can disable this warning by adding

        home.enableNixpkgsReleaseCheck = false;

      to your configuration.
    ''
  ];

  nixpkgs.overlays = [
    (final: prev: {
      lib = prev.lib.extend (
        final: prev: {
          trivial = prev.trivial // {
            release = pkgsRelease;
          };
        }
      );
    })
  ];
}
