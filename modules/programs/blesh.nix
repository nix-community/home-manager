{ config, lib, pkgs, ... }:

with lib;

let cfg = config.programs.blesh;
in {
  meta.maintainers = [ maintainers.aiotter ];

  options.programs.blesh = {
    enable = mkEnableOption "ble.sh";

    package = mkPackageOption pkgs "ble.sh" { default = [ "blesh" ]; };

    enableBashIntegration = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Load ble.sh at the beginning of `~/.bashrc` and attach it at the end.
        No effect if <code>programs.bash.enable</code> is false.
      '';
    };

    options = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = ''
        Change setting variables with <code>bleopt</code> function.
      '';
      example = { complete_auto_delay = "300"; };
    };

    faces = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = ''
        Change graphic settings with <code>ble-face</code> function.
      '';
      example = { region = "bg=60,fg=white"; };
    };

    imports = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        Search listed script files and sources them with <code>ble-import</code> if they are not yet sourced. Scripts are searched from <code>import_path</code> setting variables.
        Use <xref linkend="opt-programs.blesh.blercExtra"/> for delayed imports.
      '';
      example = [ "contrib/bash-preexec" ];
    };

    blercExtra = mkOption {
      type = types.str;
      default = "";
      description = ''
        Extra configlations to be added at the end of <filename>~/.blerc</filename>.
      '';
      example = ''
        function my/complete-load-hook {
          bleopt complete_auto_delay=300
        }

        blehook/eval-after-load complete my/complete-load-hook
      '';
    };
  };

  config = let
    stringifyAttrs = cmd: options:
      concatStringsSep "\n"
      (mapAttrsToList (k: v: "${cmd} ${k}=${escapeShellArg v}") options);
    stringifyLists = cmd: options:
      concatStringsSep "\n" (map (v: "${cmd} ${escapeShellArg v}") options);
    optionsStr = stringifyAttrs "bleopt" cfg.options;
    facesStr = stringifyAttrs "ble-face" cfg.faces;
    importsStr = stringifyLists "ble-import" cfg.imports;
  in mkIf cfg.enable {
    home.packages = [ cfg.package ];

    home.file.".blerc".source = pkgs.writeTextFile {
      name = "blerc";
      text =
        concatStringsSep "\n" [ optionsStr facesStr importsStr cfg.blercExtra ];
      checkPhase = ''
        ${pkgs.stdenv.shellDryRun} "$target"
      '';
    };

    programs.bash.bashrcExtra = mkIf cfg.enableBashIntegration (mkBefore ''
      [[ $- == *i* ]] && source '${config.programs.blesh.package}/share/blesh/ble.sh' --noattach
    '');

    programs.bash.initExtra = mkIf cfg.enableBashIntegration (mkAfter ''
      [[ ''${BLE_VERSION-} ]] && ble-attach
    '');
  };
}
