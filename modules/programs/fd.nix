{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption types;
in
{
  meta.maintainers = [ lib.maintainers.uncenter ];

  options.programs.fd = {
    enable = lib.mkEnableOption "fd, a simple, fast and user-friendly alternative to {command}`find`";

    ignores = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [
        ".git/"
        "*.bak"
      ];
      description = "List of paths that should be globally ignored.";
    };

    hidden = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Search hidden files and directories ({option}`--hidden` argument).
      '';
    };

    extraOptions = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [
        "--no-ignore"
        "--absolute-path"
      ];
      description = ''
        Extra command line options passed to fd.
      '';
    };

    package = lib.mkPackageOption pkgs "fd" { nullable = true; };
  };

  config =
    let
      cfg = config.programs.fd;

      args = lib.escapeShellArgs (lib.optional cfg.hidden "--hidden" ++ cfg.extraOptions);

      optionsAlias = lib.optionalAttrs (args != "") { fd = "fd ${args}"; };
    in
    lib.mkIf cfg.enable {
      home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

      programs.bash.shellAliases = optionsAlias;

      programs.zsh.shellAliases = optionsAlias;

      programs.fish.shellAliases = optionsAlias;

      programs.ion.shellAliases = optionsAlias;

      programs.nushell.shellAliases = optionsAlias;

      xdg.configFile."fd/ignore" = lib.mkIf (cfg.ignores != [ ]) {
        text = lib.concatStringsSep "\n" cfg.ignores + "\n";
      };
    };
}
