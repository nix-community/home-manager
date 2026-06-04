{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkIf
    mkOption
    optionalAttrs
    types
    ;

  cfg = config.programs.sh;

  writePosixScript =
    name: text:
    pkgs.writeTextFile {
      inherit name text;
      checkPhase = ''
        ${pkgs.stdenv.shellDryRun} "$target"
      '';
    };

in
{
  meta.maintainers = [ lib.maintainers.noodlez1232 ];

  options = {
    programs.sh = {
      enable = lib.mkEnableOption "configuration of POSIX compliant shells (e.g. runtime shells)" // {
        default = config.programs.bash.enable;
        defaultText = lib.literalMD "[](#opt-programs.bash.enable)";
        example = true;
      };

      historySize = mkOption {
        type = types.nullOr types.int;
        default = 10000;
        description = "Number of history lines to keep in memory.";
      };

      shellAliases = mkOption {
        default = { };
        type = types.attrsOf types.str;
        example = lib.literalExpression ''
          {
            ll = "ls -l";
            ".." = "cd ..";
          }
        '';
        description = ''
          An attribute set that maps aliases (the top level attribute names in
          this option) to command strings or directly to build outputs.
        '';
      };

      sessionVariables = mkOption {
        default = { };
        type =
          with types;
          lazyAttrsOf (
            nullOr (oneOf [
              str
              path
              int
              float
              bool
            ])
          );
        example = {
          MAILCHECK = 30;
        };
        description = ''
          Environment variables that will be set for the POSIX shell session.

          Setting a value to `null` will skip setting the variable at all, which
          may be useful when overriding.
        '';
      };

      profileExtra = mkOption {
        default = "";
        type = types.lines;
        description = ''
          Extra commands that should be run when initializing a login
          shell.
        '';
      };

      initExtra = mkOption {
        default = "";
        type = types.lines;
        description = ''
          Extra commands that should be run when initializing an
          interactive shell.
        '';
      };
    };
  };

  config =
    let
      aliasesStr = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (k: v: "alias ${k}=${lib.escapeShellArg v}") cfg.shellAliases
      );

      sessionVarsStr = config.lib.shell.exportAll cfg.sessionVariables;

      historyControlStr = (
        lib.concatStringsSep "\n" (
          lib.mapAttrsToList (n: v: "${n}=${v}") (
            optionalAttrs (cfg.historySize != null) {
              HISTSIZE = toString cfg.historySize;
            }
          )
        )
      );
    in
    mkIf cfg.enable {
      home.file.".profile".source = writePosixScript "profile" ''
        . "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh"

        ENV="$HOME/.shinit"; export ENV

        ${sessionVarsStr}

        ${cfg.profileExtra}
      '';

      home.file.".shinit".source = writePosixScript "shinit" ''
        ${historyControlStr}

        ${aliasesStr}

        ${cfg.initExtra}
      '';
    };
}
