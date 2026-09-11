# contains special options which can only be used on the default profile
# these are parsed by the parent module
{
  lib,
  ...
}:
let
  inherit (lib) types;
  inherit (lib.options) mkOption;
  hint = "Can only be set for the default profile, but it applies to all profiles.";
in
{
  _class = "homeManager.vscodeProfile";

  options = {

    enableUpdateCheck = mkOption {
      type = with types; nullOr bool;
      default = null;
      description = ''
        Whether to enable update checks/notifications.
        ${hint}
      '';
    };

    enableExtensionUpdateCheck = mkOption {
      type = with types; nullOr bool;
      default = null;
      description = ''
        Whether to enable update notifications for extensions.
        ${hint}
      '';
    };

  };

}
