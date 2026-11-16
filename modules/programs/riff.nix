{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.riff;

  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    mkPackageOption
    types
    ;
in
{
  meta.maintainers = with lib.maintainers; [ khaneliman ];

  imports =
    lib.mapAttrsToList
      (name: message: lib.mkRemovedOptionModule [ "programs" "git" "riff" name ] message)
      {
        enable = "Use `programs.riff.enable` and `programs.riff.enableGitIntegration` instead.";
        package = "Use `programs.riff.package` instead.";
        commandLineOptions = "Use `programs.riff.commandLineOptions` instead.";
      };

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
      example = [ "--no-adds-only-special" ];
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

  config = lib.mkMerge [
    (mkIf cfg.enable {
      home.packages = [ cfg.package ];

      home.sessionVariables = mkIf (cfg.commandLineOptions != "") {
        RIFF = cfg.commandLineOptions;
      };
    })

    (mkIf (cfg.enable && cfg.enableGitIntegration) {
      programs.git = {
        enable = lib.mkDefault true;
        iniContent =
          let
            riffExe = baseNameOf (lib.getExe cfg.package);
          in
          lib.hm.git.diffPagerConfig riffExe
          // {
            interactive.diffFilter = "${riffExe} --color=on";
          };
      };
    })
  ];
}
