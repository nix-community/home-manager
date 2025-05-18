{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.programs.blesh;
in
{
  meta.maintainers = [ lib.hm.maintainers.ajhalili2006 ];

  options.programs.blesh = {
    enable = mkEnableOption "ble.sh";

    package = mkPackageOption pkgs "ble.sh" { default = [ "blesh" ]; };

    attach = mkOption {
      type = types.str;
      default = "none";
      example = "prompt";
      description = ''
        Sets the strategy of <code>ble-attach</code>. Defaults to <code>prompt</code>, which
        ble.sh attaches to the session before the first prompt using <code>PROMPT_COMMAND</code>.
        If <code>none</code>, ble.sh will not attach to the session and will add an additional line of
        shell code on your <code>programs.bash.initExtra</code> to call <code>ble-attach</code>.
      '';
    };

    enableBashIntegration = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Load ble.sh at the beginning of `~/.bashrc` and attach it at the end.
        No effect if <code>programs.bash.enable</code> is false.
      '';
    };

    rcfile =
      let
        stringifyAttrs =
          cmd: options:
          concatStringsSep "\n" (mapAttrsToList (k: v: "${cmd} ${k}=${escapeShellArg v}") options);
        stringifyLists =
          cmd: options: concatStringsSep "\n" (map (v: "${cmd} ${escapeShellArg v}") options);
        optionsStr = stringifyAttrs "bleopt" cfg.options;
        facesStr = stringifyAttrs "ble-face" cfg.faces;
        importsStr = stringifyLists "ble-import" cfg.imports;
        blerc = pkgs.writeTextFile {
          name = "blerc";
          text = concatStringsSep "\n" [
            optionsStr
            facesStr
            importsStr
            cfg.blercExtra
          ];
          checkPhase = ''
            ${pkgs.stdenv.shellDryRun} "$target"
          '';
        };
      in
      mkOption {
        type = types.nullOr (types.either types.path types.str);
        default = blerc;
        defaultText = "Path to the generated file";
        example = "~/.blerc";
        description = ''
          Path of the ble init file. This value will be passed to ble.sh as a shell option <code>--rcfile</code>.
          Set to <code>null</code> not to specify rcfile and let ble.sh load a file from the default path.
        '';
      };

    extraArgs = mkOption {
      type = types.nullOr (types.either types.str (types.listOf types.str));
      default = null;
      example = [
        "--noinputrc"
        "--keep-rlvars"
      ];
      apply =
        args:
        if isList args then
          args
        else if args == null then
          [ ]
        else
          [ args ];
      description = ''
        Shell options to call ble.sh with.
      '';
    };

    options = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = ''
        Change setting variables with <code>bleopt</code> function.
      '';
      example = {
        complete_auto_delay = "300";
      };
    };

    faces = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = ''
        Change graphic settings with <code>ble-face</code> function.
      '';
      example = {
        region = "bg=60,fg=white";
      };
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

  config =
    let
      args = escapeShellArgs (optional (cfg.rcfile != null) "--rcfile=${cfg.rcfile}" ++ cfg.extraArgs);
    in
    mkIf cfg.enable {
      home.packages = [ cfg.package ];

      programs.bash.bashrcExtra = mkIf cfg.enableBashIntegration (mkBefore ''
        [[ $- == *i* ]] && source '${config.programs.blesh.package}/share/blesh/ble.sh' --attach=${cfg.attach} ${args}
      '');

      programs.bash.initExtra = mkIf cfg.enableBashIntegration (mkAfter ''
        [[ ''${BLE_VERSION-} ]] && ble-attach
      '');
    };
}
