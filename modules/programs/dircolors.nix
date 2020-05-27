{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.dircolors;

  formatLine = n: v: "${n} ${toString v}";
in {
  meta.maintainers = [ hm.maintainers.justinlovinger ];

  options.programs.dircolors = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to manage <filename>.dir_colors</filename>
        and set <code>LS_COLORS</code>.
      '';
    };

    enableBashIntegration = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to enable Bash integration.
      '';
    };

    enableFishIntegration = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to enable Fish integration.
      '';
    };

    enableZshIntegration = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to enable Zsh integration.
      '';
    };

    settings = mkOption {
      type = with types; attrsOf str;
      default = { };
      description = ''
        Options to add to <filename>.dir_colors</filename> file.
        See <command>dircolors --print-database</command>
        for options.
      '';
      example = literalExample ''
        {
          OTHER_WRITABLE = "30;46";
          ".sh" = "01;32";
          ".csh" = "01;32";
        }
      '';
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Extra lines added to <filename>.dir_colors</filename> file.
      '';
    };
  };

  config = mkIf cfg.enable {
    # Add default settings from `dircolors --print-database`.
    programs.dircolors.settings = {
      RESET = mkDefault "0";
      DIR = mkDefault "01;34";
      LINK = mkDefault "01;36";
      MULTIHARDLINK = mkDefault "00";
      FIFO = mkDefault "40;33";
      SOCK = mkDefault "01;35";
      DOOR = mkDefault "01;35";
      BLK = mkDefault "40;33;01";
      CHR = mkDefault "40;33;01";
      ORPHAN = mkDefault "40;31;01";
      MISSING = mkDefault "00";
      SETUID = mkDefault "37;41";
      SETGID = mkDefault "30;43";
      CAPABILITY = mkDefault "30;41";
      STICKY_OTHER_WRITABLE = mkDefault "30;42";
      OTHER_WRITABLE = mkDefault "34;42";
      STICKY = mkDefault "37;44";
      EXEC = mkDefault "01;32";
      ".tar" = mkDefault "01;31";
      ".tgz" = mkDefault "01;31";
      ".arc" = mkDefault "01;31";
      ".arj" = mkDefault "01;31";
      ".taz" = mkDefault "01;31";
      ".lha" = mkDefault "01;31";
      ".lz4" = mkDefault "01;31";
      ".lzh" = mkDefault "01;31";
      ".lzma" = mkDefault "01;31";
      ".tlz" = mkDefault "01;31";
      ".txz" = mkDefault "01;31";
      ".tzo" = mkDefault "01;31";
      ".t7z" = mkDefault "01;31";
      ".zip" = mkDefault "01;31";
      ".z" = mkDefault "01;31";
      ".dz" = mkDefault "01;31";
      ".gz" = mkDefault "01;31";
      ".lrz" = mkDefault "01;31";
      ".lz" = mkDefault "01;31";
      ".lzo" = mkDefault "01;31";
      ".xz" = mkDefault "01;31";
      ".zst" = mkDefault "01;31";
      ".tzst" = mkDefault "01;31";
      ".bz2" = mkDefault "01;31";
      ".bz" = mkDefault "01;31";
      ".tbz" = mkDefault "01;31";
      ".tbz2" = mkDefault "01;31";
      ".tz" = mkDefault "01;31";
      ".deb" = mkDefault "01;31";
      ".rpm" = mkDefault "01;31";
      ".jar" = mkDefault "01;31";
      ".war" = mkDefault "01;31";
      ".ear" = mkDefault "01;31";
      ".sar" = mkDefault "01;31";
      ".rar" = mkDefault "01;31";
      ".alz" = mkDefault "01;31";
      ".ace" = mkDefault "01;31";
      ".zoo" = mkDefault "01;31";
      ".cpio" = mkDefault "01;31";
      ".7z" = mkDefault "01;31";
      ".rz" = mkDefault "01;31";
      ".cab" = mkDefault "01;31";
      ".wim" = mkDefault "01;31";
      ".swm" = mkDefault "01;31";
      ".dwm" = mkDefault "01;31";
      ".esd" = mkDefault "01;31";
      ".jpg" = mkDefault "01;35";
      ".jpeg" = mkDefault "01;35";
      ".mjpg" = mkDefault "01;35";
      ".mjpeg" = mkDefault "01;35";
      ".gif" = mkDefault "01;35";
      ".bmp" = mkDefault "01;35";
      ".pbm" = mkDefault "01;35";
      ".pgm" = mkDefault "01;35";
      ".ppm" = mkDefault "01;35";
      ".tga" = mkDefault "01;35";
      ".xbm" = mkDefault "01;35";
      ".xpm" = mkDefault "01;35";
      ".tif" = mkDefault "01;35";
      ".tiff" = mkDefault "01;35";
      ".png" = mkDefault "01;35";
      ".svg" = mkDefault "01;35";
      ".svgz" = mkDefault "01;35";
      ".mng" = mkDefault "01;35";
      ".pcx" = mkDefault "01;35";
      ".mov" = mkDefault "01;35";
      ".mpg" = mkDefault "01;35";
      ".mpeg" = mkDefault "01;35";
      ".m2v" = mkDefault "01;35";
      ".mkv" = mkDefault "01;35";
      ".webm" = mkDefault "01;35";
      ".ogm" = mkDefault "01;35";
      ".mp4" = mkDefault "01;35";
      ".m4v" = mkDefault "01;35";
      ".mp4v" = mkDefault "01;35";
      ".vob" = mkDefault "01;35";
      ".qt" = mkDefault "01;35";
      ".nuv" = mkDefault "01;35";
      ".wmv" = mkDefault "01;35";
      ".asf" = mkDefault "01;35";
      ".rm" = mkDefault "01;35";
      ".rmvb" = mkDefault "01;35";
      ".flc" = mkDefault "01;35";
      ".avi" = mkDefault "01;35";
      ".fli" = mkDefault "01;35";
      ".flv" = mkDefault "01;35";
      ".gl" = mkDefault "01;35";
      ".dl" = mkDefault "01;35";
      ".xcf" = mkDefault "01;35";
      ".xwd" = mkDefault "01;35";
      ".yuv" = mkDefault "01;35";
      ".cgm" = mkDefault "01;35";
      ".emf" = mkDefault "01;35";
      ".ogv" = mkDefault "01;35";
      ".ogx" = mkDefault "01;35";
      ".aac" = mkDefault "00;36";
      ".au" = mkDefault "00;36";
      ".flac" = mkDefault "00;36";
      ".m4a" = mkDefault "00;36";
      ".mid" = mkDefault "00;36";
      ".midi" = mkDefault "00;36";
      ".mka" = mkDefault "00;36";
      ".mp3" = mkDefault "00;36";
      ".mpc" = mkDefault "00;36";
      ".ogg" = mkDefault "00;36";
      ".ra" = mkDefault "00;36";
      ".wav" = mkDefault "00;36";
      ".oga" = mkDefault "00;36";
      ".opus" = mkDefault "00;36";
      ".spx" = mkDefault "00;36";
      ".xspf" = mkDefault "00;36";
    };

    home.file.".dir_colors".text = concatStringsSep "\n" ([ ]
      ++ optional (cfg.extraConfig != "") cfg.extraConfig
      ++ mapAttrsToList formatLine cfg.settings) + "\n";

    programs.bash.initExtra = mkIf cfg.enableBashIntegration ''
      eval $(${pkgs.coreutils}/bin/dircolors -b ~/.dir_colors)
    '';

    programs.fish.shellInit = mkIf cfg.enableFishIntegration ''
      eval (${pkgs.coreutils}/bin/dircolors -c ~/.dir_colors)
    '';

    # Set `LS_COLORS` before Oh My Zsh and `initExtra`.
    programs.zsh.initExtraBeforeCompInit = mkIf cfg.enableZshIntegration ''
      eval $(${pkgs.coreutils}/bin/dircolors -b ~/.dir_colors)
    '';
  };
}
