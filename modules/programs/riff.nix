{
  config,
  options,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.riff;

  inherit (lib)
    literalExpression
    mkEnableOption
    mkIf
    mkOption
    mkPackageOption
    types
    ;
in
{
  meta.maintainers = with lib.maintainers; [ khaneliman ];

  imports = [
    (lib.mkRenamedOptionModule [ "programs" "git" "riff" "enable" ] [ "programs" "riff" "enable" ])
    (lib.mkRenamedOptionModule [ "programs" "git" "riff" "package" ] [ "programs" "riff" "package" ])
    (lib.mkRenamedOptionModule
      [ "programs" "git" "riff" "commandLineOptions" ]
      [ "programs" "riff" "commandLineOptions" ]
    )
  ];

  options.programs.riff = {
    enable = mkEnableOption "" // {
      description = ''
        Enable the <command>riff</command> diff highlighter.
        See <link xlink:href="https://github.com/walles/riff" />.
      '';
    };

    package = mkPackageOption pkgs "riffdiff" { };

    commandLineOptions = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = literalExpression ''[ "--no-adds-only-special" ]'';
      apply = lib.concatStringsSep " ";
      description = ''
        Command line arguments to include in the <command>RIFF</command> environment variable.

        Run <command>riff --help</command> for a full list of options
      '';
    };

    enableGitIntegration = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable git integration for riff.

        When enabled, riff will be configured as git's pager for diff, log, and show commands.
      '';
    };
  };

  config =
    let
      oldOption = lib.attrByPath [ "programs" "git" "riff" "enable" ] null options;
      oldOptionEnabled =
        oldOption != null && oldOption.isDefined && (builtins.length oldOption.files) > 0;
    in
    lib.mkMerge [
      (mkIf cfg.enable {
        home.packages = [ cfg.package ];

        home.sessionVariables = mkIf (cfg.commandLineOptions != "") {
          RIFF = cfg.commandLineOptions;
        };

        # Auto-enable git integration if programs.git.riff.enable was set to true
        programs.riff.enableGitIntegration = lib.mkIf oldOptionEnabled (lib.mkOverride 1490 true);

        warnings =
          lib.optional
            (cfg.enableGitIntegration && options.programs.riff.enableGitIntegration.highestPrio == 1490)
            "`programs.riff.enableGitIntegration` automatic enablement is deprecated. Please explicitly set `programs.riff.enableGitIntegration = true`.";
      })

      (mkIf (cfg.enable && cfg.enableGitIntegration) {
        programs.git = {
          enable = lib.mkDefault true;
          iniContent =
            let
              riffExe = baseNameOf (lib.getExe cfg.package);
            in
            {
              pager = {
                diff = riffExe;
                log = riffExe;
                show = riffExe;
              };

              interactive.diffFilter = "${riffExe} --color=on";
            };
        };
      })
    ];
}
