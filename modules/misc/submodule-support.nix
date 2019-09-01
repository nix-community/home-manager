{ lib, ... }:

with lib;

{
  meta.maintainers = [ maintainers.rycee ];

  options.submoduleSupport = {
    enable = mkOption {
      type = types.bool;
      default = false;
      internal = true;
      description = ''
        Whether the Home Manager module system is used as a submodule
        in, for example, NixOS or nix-darwin.
      '';
    };

    externalPackageInstall = mkOption {
      type = types.bool;
      default = false;
      internal = true;
      description = ''
        Whether the packages of <option>home.packages</option> are
        installed separately from the Home Manager activation script.
        In NixOS, for example, this may be accomplished by installing
        the packages through
        <option>users.users.‹name?›.packages</option>.
      '';
    };
  };
}
