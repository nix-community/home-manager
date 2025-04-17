{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) literalExpression mkOption types;

  cfg = config.xdg.userDirs;

in
{
  meta.maintainers = with lib.maintainers; [ euxane ];

  imports = [
    (lib.mkRenamedOptionModule
      [ "xdg" "userDirs" "publishShare" ]
      [
        "xdg"
        "userDirs"
        "publicShare"
      ]
    )
  ];

  options.xdg.userDirs = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to manage {file}`$XDG_CONFIG_HOME/user-dirs.dirs`.

        The generated file is read-only.
      '';
    };

    # Well-known directory list from
    # https://gitlab.freedesktop.org/xdg/xdg-user-dirs/blob/master/man/user-dirs.dirs.xml

    desktop = mkOption {
      type = types.nullOr config.lib.homePath.type;
      default = "~/Desktop";
      description = "The Desktop directory.";
    };

    documents = mkOption {
      type = types.nullOr config.lib.homePath.type;
      default = "~/Documents";
      description = "The Documents directory.";
    };

    download = mkOption {
      type = types.nullOr config.lib.homePath.type;
      default = "~/Downloads";
      description = "The Downloads directory.";
    };

    music = mkOption {
      type = types.nullOr config.lib.homePath.type;
      default = "~/Music";
      description = "The Music directory.";
    };

    pictures = mkOption {
      type = types.nullOr config.lib.homePath.type;
      default = "~/Pictures";
      description = "The Pictures directory.";
    };

    publicShare = mkOption {
      type = types.nullOr config.lib.homePath.type;
      default = "~/Public";
      description = "The Public share directory.";
    };

    templates = mkOption {
      type = types.nullOr config.lib.homePath.type;
      default = "~/Templates";
      description = "The Templates directory.";
    };

    videos = mkOption {
      type = types.nullOr config.lib.homePath.type;
      default = "~/Videos";
      description = "The Videos directory.";
    };

    extraConfig = mkOption {
      type = with types; attrsOf config.lib.homePath.type;
      default = { };
      defaultText = literalExpression "{ }";
      example = literalExpression ''
        {
          XDG_MISC_DIR = "~/Misc";
        }
      '';
      description = "Other user directories.";
    };

    createDirectories = lib.mkEnableOption "automatic creation of the XDG user directories";
  };

  config =
    let
      directories =
        (lib.filterAttrs (n: v: !isNull v) {
          XDG_DESKTOP_DIR = cfg.desktop;
          XDG_DOCUMENTS_DIR = cfg.documents;
          XDG_DOWNLOAD_DIR = cfg.download;
          XDG_MUSIC_DIR = cfg.music;
          XDG_PICTURES_DIR = cfg.pictures;
          XDG_PUBLICSHARE_DIR = cfg.publicShare;
          XDG_TEMPLATES_DIR = cfg.templates;
          XDG_VIDEOS_DIR = cfg.videos;
        })
        // cfg.extraConfig;
    in
    lib.mkIf cfg.enable {
      assertions = [
        (lib.hm.assertions.assertPlatform "xdg.userDirs" pkgs lib.platforms.linux)
      ];

      xdg.configFile."user-dirs.dirs".text =
        let
          # For some reason, these need to be wrapped with quotes to be valid.
          wrapped = lib.mapAttrs (
            _: dir:
            ''"${dir.render "$HOME" (lib.replaceStrings [ "$" ''\'' ''"'' ] [ ''\$'' ''\\'' ''\"'' ])}"''
          ) directories;
        in
        lib.generators.toKeyValue { } wrapped;

      xdg.configFile."user-dirs.conf".text = "enabled=False";

      home.sessionVariables = lib.mapAttrs (_: dir: dir.environment) directories;

      home.activation.createXdgUserDirectories = lib.mkIf cfg.createDirectories (
        let
          directoriesList = lib.attrValues directories;
          mkdir = (dir: ''[[ -L ${dir.shell} ]] || run mkdir -p $VERBOSE_ARG ${dir.shell}'');
        in
        lib.hm.dag.entryAfter [ "linkGeneration" ] (
          lib.strings.concatMapStringsSep "\n" mkdir directoriesList
        )
      );
    };
}
