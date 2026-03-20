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

    package = lib.mkPackageOption pkgs "xdg-user-dirs" { nullable = true; };

    # Well-known directory list from
    # https://gitlab.freedesktop.org/xdg/xdg-user-dirs/blob/master/man/user-dirs.dirs.xml

    desktop = mkOption {
      type = with types; nullOr (coercedTo path toString str);
      default = "${config.home.homeDirectory}/Desktop";
      defaultText = literalExpression ''"''${config.home.homeDirectory}/Desktop"'';
      description = "The Desktop directory.";
    };

    documents = mkOption {
      type = with types; nullOr (coercedTo path toString str);
      default = "${config.home.homeDirectory}/Documents";
      defaultText = literalExpression ''"''${config.home.homeDirectory}/Documents"'';
      description = "The Documents directory.";
    };

    download = mkOption {
      type = with types; nullOr (coercedTo path toString str);
      default = "${config.home.homeDirectory}/Downloads";
      defaultText = literalExpression ''"''${config.home.homeDirectory}/Downloads"'';
      description = "The Downloads directory.";
    };

    music = mkOption {
      type = with types; nullOr (coercedTo path toString str);
      default = "${config.home.homeDirectory}/Music";
      defaultText = literalExpression ''"''${config.home.homeDirectory}/Music"'';
      description = "The Music directory.";
    };

    pictures = mkOption {
      type = with types; nullOr (coercedTo path toString str);
      default = "${config.home.homeDirectory}/Pictures";
      defaultText = literalExpression ''"''${config.home.homeDirectory}/Pictures"'';
      description = "The Pictures directory.";
    };

    publicShare = mkOption {
      type = with types; nullOr (coercedTo path toString str);
      default = "${config.home.homeDirectory}/Public";
      defaultText = literalExpression ''"''${config.home.homeDirectory}/Public"'';
      description = "The Public share directory.";
    };

    templates = mkOption {
      type = with types; nullOr (coercedTo path toString str);
      default = "${config.home.homeDirectory}/Templates";
      defaultText = literalExpression ''"''${config.home.homeDirectory}/Templates"'';
      description = "The Templates directory.";
    };

    videos = mkOption {
      type = with types; nullOr (coercedTo path toString str);
      default = "${config.home.homeDirectory}/Videos";
      defaultText = literalExpression ''"''${config.home.homeDirectory}/Videos"'';
      description = "The Videos directory.";
    };

    extraConfig = mkOption {
      type = with types; attrsOf (coercedTo path toString str);
      default = { };
      defaultText = literalExpression "{ }";
      example = literalExpression ''
        {
          MISC = "''${config.home.homeDirectory}/Misc";
        }
      '';
      apply =
        if lib.versionOlder config.home.stateVersion "26.05" then
          lib.mapAttrs' (
            k:
            let
              matches = lib.match "XDG_(.*)_DIR" k;
            in
            lib.nameValuePair (
              if matches == null then
                k
              else
                let
                  name = lib.elemAt matches 0;
                in
                lib.warn "using keys like ‘${k}’ for xdg.userDirs.extraConfig is deprecated in favor of keys like ‘${name}’" name
            )
          )
        else
          lib.id;
      description = ''
        Other user directories.

        The key ‘MISC’ corresponds to the user-dirs entry ‘XDG_MISC_DIR’.
      '';
    };

    createDirectories = lib.mkEnableOption "automatic creation of the XDG user directories";

    setSessionVariables = mkOption {
      type = with types; bool;
      default = lib.versionOlder config.home.stateVersion "26.05";
      defaultText = literalExpression ''
        lib.versionOlder config.home.stateVersion "26.05"
      '';
      description = ''
        Whether to set the XDG user dir environment variables, like
        `XDG_DESKTOP_DIR`.

        ::: {.note}
        The recommended way to get these values is via the `xdg-user-dir`
        command or by processing `$XDG_CONFIG_HOME/user-dirs.dirs` directly in
        your application.
        :::

        This defaults to `true` for state version < 26.05 and `false` otherwise.
      '';
    };
  };

  config =
    let
      directories =
        (lib.filterAttrs (n: v: !isNull v) {
          DESKTOP = cfg.desktop;
          DOCUMENTS = cfg.documents;
          DOWNLOAD = cfg.download;
          MUSIC = cfg.music;
          PICTURES = cfg.pictures;
          PUBLICSHARE = cfg.publicShare;
          TEMPLATES = cfg.templates;
          VIDEOS = cfg.videos;
        })
        // cfg.extraConfig;

      bindings = lib.mapAttrs' (k: lib.nameValuePair "XDG_${k}_DIR") directories;
    in
    lib.mkIf cfg.enable {
      xdg.configFile."user-dirs.dirs".text =
        let
          # For some reason, these need to be wrapped with quotes to be valid.
          wrapped = lib.mapAttrs (_: value: ''"${value}"'') bindings;
        in
        lib.generators.toKeyValue { } wrapped;

      xdg.configFile."user-dirs.conf".text = "enabled=False";

      home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

      home.sessionVariables = lib.mkIf cfg.setSessionVariables bindings;

      home.activation.createXdgUserDirectories = lib.mkIf cfg.createDirectories (
        let
          directoriesList = lib.attrValues directories;
          mkdir = (dir: ''[[ -L "${dir}" ]] || run mkdir -p $VERBOSE_ARG "${dir}"'');
        in
        lib.hm.dag.entryAfter [ "linkGeneration" ] (
          lib.strings.concatMapStringsSep "\n" mkdir directoriesList
        )
      );
    };
}
