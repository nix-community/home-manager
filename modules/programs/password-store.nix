{ config, lib, pkgs, ... }:

with lib;

{
  meta.maintainers = with maintainers; [ pacien ];

  options.programs.password-store = {
    enable = mkEnableOption "Password store";

    package = mkOption {
      type = types.package;
      default = pkgs.pass;
      defaultText = "pkgs.pass";
      example = literalExample ''
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
      example = literalExample ''
        {
          PASSWORD_STORE_DIR = "/some/directory";
          PASSWORD_STORE_KEY = "12345678";
          PASSWORD_STORE_CLIP_TIME = "60";
        }
      '';
      description = ''
        <literal>pass</literal> environment variables dictionary.

        See the "Environment variables" section of
        <citerefentry>
          <refentrytitle>pass</refentrytitle>
          <manvolnum>1</manvolnum>
        </citerefentry>
        and the extension man pages for more information about the available keys.

        The user shell must properly source the profile session variables as described in
        <link xlink:href="https://github.com/rycee/home-manager#installation">the installation guide</link>.
      '';
    };
  };

  config = let
    cfg = config.programs.password-store;
  in mkIf cfg.enable {
    home.packages = [ cfg.package ];
    home.sessionVariables = cfg.settings;
  };
}
