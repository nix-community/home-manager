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
      default =
        if lib.versionOlder config.home.stateVersion "25.11" then
          {
            PASSWORD_STORE_DIR = "${config.xdg.dataHome}/password-store";
          }
        else
          { };
      defaultText = literalExpression ''
        { }                                                       for state version ≥ 25.11
        { PASSWORD_STORE_DIR = "$XDG_DATA_HOME/password-store"; } for state version < 25.11
      '';
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

    enableBashIntegration = lib.hm.shell.mkBashIntegrationOption { inherit config; };

    enableFishIntegration = lib.hm.shell.mkFishIntegrationOption { inherit config; };

    enableZshIntegration = lib.hm.shell.mkZshIntegrationOption { inherit config; };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];
    home.sessionVariables = cfg.settings;

    programs.bash.initExtra = lib.mkIf cfg.enableBashIntegration ''
      source ${cfg.package}/share/bash-completion/completions/pass
    '';

    programs.fish.shellInit = lib.mkIf cfg.enableFishIntegration ''
      source ${cfg.package}/share/fish/vendor_completions.d/pass.fish
    '';

    programs.zsh.initContent = lib.mkIf cfg.enableZshIntegration ''
      source ${cfg.package}/share/zsh/site-functions/_pass
    '';

    services.pass-secret-service = lib.mkIf (builtins.hasAttr "PASSWORD_STORE_DIR" cfg.settings) {
      storePath = cfg.settings.PASSWORD_STORE_DIR;
    };

    xsession.importedVariables = lib.mkIf config.xsession.enable (
      lib.mapAttrsToList (name: value: name) cfg.settings
    );
  };
}
