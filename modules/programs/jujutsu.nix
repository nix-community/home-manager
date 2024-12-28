{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.jujutsu;
  tomlFormat = pkgs.formats.toml { };

  configDir = if pkgs.stdenv.isDarwin then
    "Library/Application Support"
  else
    config.xdg.configHome;

in {
  meta.maintainers = [ maintainers.shikanime ];

  imports = let
    mkRemovedShellIntegration = name:
      mkRemovedOptionModule [ "programs" "jujutsu" "enable${name}Integration" ]
      "This option is no longer necessary.";
  in map mkRemovedShellIntegration [ "Bash" "Fish" "Zsh" ];

  options.programs.jujutsu = {
    enable =
      mkEnableOption "a Git-compatible DVCS that is both simple and powerful";

    package = mkPackageOption pkgs "jujutsu" { };

    ediff = mkOption {
      type = types.bool;
      default = config.programs.emacs.enable;
      defaultText = literalExpression "config.programs.emacs.enable";
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
    home.packages = [ cfg.package ];

    home.file."${configDir}/jj/config.toml" = mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "jujutsu-config" (cfg.settings
        // optionalAttrs (cfg.ediff) (let
          emacsDiffScript = pkgs.writeShellScriptBin "emacs-ediff" ''
            set -euxo pipefail
            ${config.programs.emacs.package}/bin/emacsclient -c --eval "(ediff-merge-files-with-ancestor \"$1\" \"$2\" \"$3\" nil \"$4\")"
          '';
        in {
          merge-tools.ediff = {
            program = getExe emacsDiffScript;
            merge-args = [ "$left" "$right" "$base" "$output" ];
          };
        }));
    };
  };
}
