{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.password-store;

in {
  meta.maintainers = with maintainers; [ euxane ];

  options.programs.password-store = {
    enable = mkEnableOption "Password store";

    package = mkOption {
      type = types.package;
      default = pkgs.pass;
      defaultText = literalExpression "pkgs.pass";
      example = literalExpression ''
        pkgs.pass.withExtensions (exts: [ exts.pass-otp ])
      '';
      description = ''
        The `pass` package to use.
        Can be used to specify extensions.
      '';
    };

    settings = mkOption rec {
      type = with types; attrsOf str;
      apply = mergeAttrs default;
      default = {
        PASSWORD_STORE_DIR = "${config.xdg.dataHome}/password-store";
      };
      defaultText = literalExpression ''
        { PASSWORD_STORE_DIR = "$XDG_DATA_HOME/password-store"; }
      '';
      example = literalExpression ''
        {
          PASSWORD_STORE_DIR = "/some/directory";
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

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];
    home.sessionVariables = cfg.settings;

    services.pass-secret-service.storePath =
      mkDefault cfg.settings.PASSWORD_STORE_DIR;

    xsession.importedVariables = mkIf config.xsession.enable
      (mapAttrsToList (name: value: name) cfg.settings);
  };
}
