{ config, lib, pkgs, ... }:

# Considerations:
#   - __monty__: eyJhb: How do you handle spaces in mappings? I.e., in rc.conf you'd have to write `a<space>b`, but in nix `"a b" = "blah";` would be possible.
#   - scope.sh might need to be patched for handling all the preview files, also adding all might be good as a option? 
#   - add option for having immutable bookmarks, tags. etc or hybrid

with lib;

let
  cfg = config.programs.ranger;

  optionsStr = key: value: optionsStrPrefix "set" key value;
  optionsStrPrefix = prefix: key: value: ''${prefix} ${key} ${(if (builtins.isBool value) then (if value == true then "true" else "false" ) else value)}'';

  # setintag
  # setlocal
  # copy{c,p,t}map
  # alias
  # eval
  keybindingsModule = types.submodule {
    options = {
      browser = mkOption {
        type = types.attrsOf types.str;
        default = { };
      };

      console = mkOption {
        type = types.attrsOf types.str;
        default = { };
      };

      pager = mkOption {
        type = types.attrsOf types.str;
        default = { };
      };

      taskview = mkOption {
        type = types.attrsOf types.str;
        default = { };
      };
    };
  };

  previewModule = types.submodule {
    options = attrsets.mapAttrs' (name: value: nameValuePair name ({
      enable = mkOption {
        type = types.bool;
        default = false;
      };

      package = mkOption {
        type = types.package;
        default = value;
      };
    })) { 
      images-ascii = pkgs.libcaca.bin; # "img2txt" (from "caca-utils") for ASCII-art image previews
      images = pkgs.w3m; # "w3mimgdisplay", "ueberzug", "mpv", "iTerm2", "kitty", "terminology" or "urxvt" for image previews
      svg = pkgs.imagemagick; # "convert" (from "imagemagick") to auto-rotate images and for SVG previews
      video = pkgs.ffmpegthumbnailer; # "ffmpegthumbnailer" for video thumbnails
      code-highlight = pkgs.highlight; # "highlight", "bat" or "pygmentize" for syntax highlighting of code
      archives = pkgs.atool; # "atool", "bsdtar", "unrar" and/or "7z" to preview archives
      archives-first-image = pkgs.libarchive; # "bsdtar", "tar", "unrar", "unzip" and/or "zipinfo" (and "sed") to preview archives as their first image
      html = pkgs.lynx; # "lynx", "w3m" or "elinks" to preview html pages
      pdf = pkgs.poppler_utils; # "pdftotext" or "mutool" (and "fmt") for textual pdf previews, "pdftoppm" to preview as image
      djvu = pkgs.djvulibre.bin; # "djvutxt" for textual DjVu previews, "ddjvu" to preview as image
      ebooks = pkgs.calibre; # "calibre" or "epub-thumbnailer" for image previews of ebooks
      torrent = pkgs.transmission; # "transmission-show" for viewing BitTorrent information
      media = pkgs.mediainfo; # "mediainfo" or "exiftool" for viewing information about media files
      opendocument = pkgs.odt2txt; # "odt2txt" for OpenDocument text files (odt, ods, odp and sxw)
      json = pkgs.jq; # "python" or "jq" for JSON files
      font = pkgs.fontforge-fonttools; # "fontimage" for font previews
    };
  };

  configModule = types.submodule {
    options = {
      settings = mkOption {
        type = with types; attrsOf (either bool str);
        default = { };
        description = ''
          TODO(change)
        '';
        example = literalExample ''
        TODO(change)
        '';
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = ''
          TODO(change)
        '';
        example = literalExample ''
        TODO(change)
        '';
      };

      keybindings = mkOption {
        type = types.nullOr keybindingsModule;
        default = null;
        description = ''
          TODO(change)
        '';
        example = literalExample ''
        TODO(change)
        '';
      };
    };
  };
in {
  options = {
    programs.ranger = {
      enable = mkEnableOption "Ranger filemanager";

      config = mkOption {
        type = types.nullOr configModule;
        default = null;
        description = "";
      };

      bookmarks = mkOption {
        type = with types; nullOr (attrsOf str);
        default = null;
        description = ''
          TODO(change)
        '';
        example = literalExample ''
        TODO(change)
        '';
      };

      # lib.attrsets.filterAttrs (do not take * when we do them all) - optional
      tagged = mkOption {
        type = with types; nullOr (attrsOf (listOf str));
        default = null;
        description = ''
          TODO(change)
        '';
        example = literalExample ''
        TODO(change)
        '';
      };

      preview = mkOption {
        type = types.nullOr previewModule;
        default = null;
        description = ''
          TODO(change)
        '';
        example = literalExample ''
        TODO(change)
        '';
      };
    };
  };

  config = mkIf cfg.enable ( mkMerge [ {
    home.packages = [
      pkgs.ranger
    ] ++ (map (x: x.package) (filter (x: x.enable) (attrsets.attrValues cfg.preview)));

    xdg.configFile."ranger/rc.conf" = let
        settings = cfg.config.settings 
          // (if (cfg.bookmarks != null)
          then { autosave_bookmarks = false; save_backtick_bookmark = false; }
          else {});
      in {
      text = (if cfg.config != null then ''
        # base settings
        ${concatStringsSep "\n" (mapAttrsToList optionsStr settings)}

        # all keybindings
        ${concatStringsSep "\n" (mapAttrsToList (optionsStrPrefix "map") cfg.config.keybindings.browser)}
        ${concatStringsSep "\n" (mapAttrsToList (optionsStrPrefix "cmap") cfg.config.keybindings.console)}
        ${concatStringsSep "\n" (mapAttrsToList (optionsStrPrefix "pmap") cfg.config.keybindings.pager)}
        ${concatStringsSep "\n" (mapAttrsToList (optionsStrPrefix "tmap") cfg.config.keybindings.taskview)}

        # extra config
        ${cfg.config.extraConfig}
        '' else null);
    };

    xdg.dataFile = {
      "ranger/bookmarks" = mkIf (cfg.bookmarks != null) {
        text = concatStringsSep "\n" (mapAttrsToList (name: path: "${name}:${path}") cfg.bookmarks);
      };

      "ranger/tagged" = mkIf (cfg.tagged != null) { 
        text = lib.concatStringsSep "\n" (lib.concatLists (lib.mapAttrsToList (n: v: builtins.map (x: "${n}:${x}") v) cfg.tagged));
      };
    };
  }]);
}
