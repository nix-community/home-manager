{ lib, ... }:
{
  imports = [
    (lib.mkRemovedOptionModule [ "services" "password-store-sync" ] ''
      Use services.git-sync instead.
    '')
    (lib.mkRemovedOptionModule [ "services" "keepassx" ] ''
      KeePassX is no longer maintained.
    '')
    (lib.mkRemovedOptionModule [ "programs" "thefuck" ] ''
      The corresponding package was removed from nixpkgs,
      consider using `programs.pay-respects` instead.
    '')
    (lib.mkRemovedOptionModule [ "programs" "octant" ] ''
      Octant is no longer maintained and project was archived.
    '')
    (lib.mkRemovedOptionModule [ "services" "barrier" ] ''
      The corresponding package was removed from nixpkgs,
      consider using `deskflow` or `input-leap` instead.
    '')
  ]
  # Just module removal
  ++ (map
    (
      opt:
      lib.mkRemovedOptionModule [ "programs" "just" opt ] ''
        'program.just' is deprecated, simply add 'pkgs.just' to 'home.packages' instead.
        See https://github.com/nix-community/home-manager/issues/3449#issuecomment-1329823502''
    )
    [
      "enable"
      "enableBashIntegration"
      "enableZshIntegration"
      "enableFishIntegration"
    ]
  );
}
