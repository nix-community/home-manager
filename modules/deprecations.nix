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
  ];
}
