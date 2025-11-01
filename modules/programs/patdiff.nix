{
  config,
  options,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.patdiff;

  inherit (lib)
    mkEnableOption
    mkIf
    mkPackageOption
    mkOption
    types
    ;
in
{
  meta.maintainers = with lib.maintainers; [ khaneliman ];

  imports = [
    (lib.mkRenamedOptionModule
      [ "programs" "git" "patdiff" "enable" ]
      [ "programs" "patdiff" "enable" ]
    )
    (lib.mkRenamedOptionModule
      [ "programs" "git" "patdiff" "package" ]
      [ "programs" "patdiff" "package" ]
    )
  ];

  options.programs.patdiff = {
    enable = mkEnableOption "" // {
      description = ''
        Whether to enable the {command}`patdiff` differ.
        See <https://opensource.janestreet.com/patdiff/>
      '';
    };

    package = mkPackageOption pkgs "patdiff" { };

    enableGitIntegration = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable git integration for patdiff.

        When enabled, patdiff will be configured as git's external diff tool.
      '';
    };
  };

  config =
    let
      oldOption = lib.attrByPath [ "programs" "git" "patdiff" "enable" ] null options;
      oldOptionEnabled =
        oldOption != null && oldOption.isDefined && (builtins.length oldOption.files) > 0;
    in
    lib.mkMerge [
      (mkIf cfg.enable {
        home.packages = [ cfg.package ];

        # Auto-enable git integration if programs.git.patdiff.enable was set to true
        programs.patdiff.enableGitIntegration = lib.mkIf oldOptionEnabled (lib.mkOverride 1490 true);

        warnings =
          lib.optional
            (cfg.enableGitIntegration && options.programs.patdiff.enableGitIntegration.highestPrio == 1490)
            "`programs.patdiff.enableGitIntegration` automatic enablement is deprecated. Please explicitly set `programs.patdiff.enableGitIntegration = true`.";
      })

      (mkIf (cfg.enable && cfg.enableGitIntegration) {
        programs.git = {
          enable = lib.mkDefault true;
          iniContent =
            let
              patdiffCommand = "${lib.getExe' cfg.package "patdiff-git-wrapper"}";
            in
            {
              diff.external = patdiffCommand;
            };
        };
      })
    ];
}
