{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.password-store;

in {
  meta.maintainers = with maintainers; [ pacien ];

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
        The <literal>pass</literal> package to use.
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
        The <literal>pass</literal> environment variables dictionary.
        </para><para>
        See the "Environment variables" section of
        <citerefentry>
          <refentrytitle>pass</refentrytitle>
          <manvolnum>1</manvolnum>
        </citerefentry>
        and the extension man pages for more information about the
        available keys.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];
    home.sessionVariables = cfg.settings;

    xsession.importedVariables = mkIf config.xsession.enable
      (mapAttrsToList (name: value: name) cfg.settings);
  };
}
