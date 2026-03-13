{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) literalExpression mkOption types;

  cfg = config.programs.password-store;

in
{
  meta.maintainers = with lib.maintainers; [ euxane ];

  options.programs.password-store = {
    enable = lib.mkEnableOption "Password store";

    package = lib.mkPackageOption pkgs "pass" {
      example = "pkgs.pass.withExtensions (exts: [ exts.pass-otp ])";
      extraDescription = "Can be used to specify extensions.";
    };

    settings = mkOption rec {
      type = with types; attrsOf str;
      apply = lib.mergeAttrs default;
      inherit
        (lib.hm.deprecations.mkStateVersionOptionDefault {
          stateVersion = config.home.stateVersion;
          since = "25.11";
          optionPath = [
            "programs"
            "password-store"
            "settings"
          ];
          legacy = {
            value = {
              PASSWORD_STORE_DIR = "${config.xdg.dataHome}/password-store";
            };
            text = ''{ PASSWORD_STORE_DIR = "$XDG_DATA_HOME/password-store"; }'';
          };
          current = {
            value = { };
            text = "{ }";
          };
        })
        default
        defaultText
        ;
      example = literalExpression ''
        {
          PASSWORD_STORE_DIR = "$\{config.xdg.dataHome\}/password-store";
          PASSWORD_STORE_KEY = "12345678";
          PASSWORD_STORE_CLIP_TIME = "60";
        }
      '';
      description = ''
        The `pass` environment variables dictionary.

        See the "Environment variables" section of
        {manpage}`pass(1)`
        and the extension man pages for more information about the
        available keys.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];
    home.sessionVariables = cfg.settings;

    services.pass-secret-service = lib.mkIf (builtins.hasAttr "PASSWORD_STORE_DIR" cfg.settings) {
      storePath = cfg.settings.PASSWORD_STORE_DIR;
    };

    xsession.importedVariables = lib.mkIf config.xsession.enable (
      lib.mapAttrsToList (name: value: name) cfg.settings
    );
  };
}
