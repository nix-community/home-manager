{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.opam;
  posixInit = shell: ''
    if (
      opam_root="''${OPAMROOT-$HOME/.opam}"
      case "$opam_root" in
        '~') opam_root="$HOME" ;;
        '~/'*) opam_root="$HOME/''${opam_root#\~/}" ;;
        "") opam_root=. ;;
      esac
      [ -f "$opam_root/config" ]
    ); then
      eval "$(${cfg.package}/bin/opam env --shell=${shell})"
    fi
  '';
in
{
  meta.maintainers = [ ];

  options.programs.opam = {
    enable = lib.mkEnableOption "Opam";

    package = lib.mkPackageOption pkgs "opam" { };

    enableBashIntegration = lib.hm.shell.mkBashIntegrationOption { inherit config; };

    enableFishIntegration = lib.hm.shell.mkFishIntegrationOption { inherit config; };

    enableZshIntegration = lib.hm.shell.mkZshIntegrationOption { inherit config; };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    programs.bash.initExtra = lib.mkIf cfg.enableBashIntegration (posixInit "bash");

    programs.zsh.initContent = lib.mkIf cfg.enableZshIntegration (posixInit "zsh");

    programs.fish.shellInit = lib.mkIf cfg.enableFishIntegration ''
      set -l opam_root "$HOME/.opam"
      if set -q OPAMROOT
        set opam_root "$OPAMROOT"
      end
      switch "$opam_root"
        case '~'
          set opam_root "$HOME"
        case '~/*'
          set opam_root "$HOME/"(string sub -s 3 -- "$opam_root")
        case ""
          set opam_root .
      end
      if test -f "$opam_root/config"
        eval (${cfg.package}/bin/opam env --shell=fish)
      end
    '';
  };
}
