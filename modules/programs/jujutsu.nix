{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkOption types;

  cfg = config.programs.jujutsu;
  tomlFormat = pkgs.formats.toml { };
in
{
  meta.maintainers = [ lib.maintainers.shikanime ];

  imports =
    let
      mkRemovedShellIntegration =
        name:
        lib.mkRemovedOptionModule [
          "programs"
          "jujutsu"
          "enable${name}Integration"
        ] "This option is no longer necessary.";
    in
    map mkRemovedShellIntegration [
      "Bash"
      "Fish"
      "Zsh"
    ];

  options.programs.jujutsu = {
    enable = lib.mkEnableOption "a Git-compatible DVCS that is both simple and powerful";

    package = lib.mkPackageOption pkgs "jujutsu" { nullable = true; };

    ediff = mkOption {
      type = types.bool;
      default = config.programs.emacs.enable;
      defaultText = lib.literalExpression "config.programs.emacs.enable";
      description = ''
        Enable ediff as a merge tool
      '';
    };

    settings = mkOption {
      type = tomlFormat.type;
      default = { };
      example = {
        user = {
          name = "John Doe";
          email = "jdoe@example.org";
        };
      };
      description = ''
        Options to add to the {file}`config.toml` file. See
        <https://github.com/martinvonz/jj/blob/main/docs/config.md>
        for options.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];

    programs.jujutsu.settings = lib.mkMerge [
      (lib.mkIf cfg.ediff {
        merge-tools.ediff =
          let
            emacsDiffScript = pkgs.writeShellScriptBin "emacs-ediff" ''
              set -euxo pipefail
              ${config.programs.emacs.package}/bin/emacsclient -c --eval "(ediff-merge-files-with-ancestor \"$1\" \"$2\" \"$3\" nil \"$4\")"
            '';
          in
          {
            program = lib.getExe emacsDiffScript;
            merge-args = [
              "$left"
              "$right"
              "$base"
              "$output"
            ];
          };
      })
    ];

    home.file."${config.xdg.configHome}/jj/config.toml" = mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "jujutsu-config" cfg.settings;
    };
  };
}
