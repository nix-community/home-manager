{ lib, pkgs, ... }:
{
  vivid-example-config = ./example-config.nix;
  vivid-shell-integration = ./shell-integration.nix;
  vivid-custom-shell-integration = {
    imports = [
      ./example-config.nix
      ./shell-integration.nix
    ];
  };
  vivid-runtime-theme =
    { pkgs, ... }:
    {
      imports = [ ./external-package.nix ];
      programs.vivid.package = pkgs.vivid;
    };
  vivid-external-package = {
    imports = [ ./external-package.nix ];
    programs.vivid.activeTheme = "molokai";
  };
}
// lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  vivid-cross-compilation = ./cross-compilation.nix;
}
