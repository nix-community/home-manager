{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.xdg.mime;

  inherit (lib)
    getExe
    getExe'
    mkOption
    types
    ;

in
{
  options = {
    xdg.mime = {
      enable = mkOption {
        type = types.bool;
        default = pkgs.stdenv.hostPlatform.isLinux;
        defaultText = lib.literalExpression "true if host platform is Linux, false otherwise";
        description = ''
          Whether to install programs and files to support the
          XDG Shared MIME-info specification and XDG MIME Applications
          specification at
          <https://specifications.freedesktop.org/shared-mime-info-spec/shared-mime-info-spec-latest.html>
          and
          <https://specifications.freedesktop.org/mime-apps-spec/mime-apps-spec-latest.html>,
          respectively.
        '';
      };

      sharedMimeInfoPackage = mkOption {
        type = types.package;
        default = pkgs.shared-mime-info;
        defaultText = lib.literalExpression "pkgs.shared-mime-info";
        description = "The package to use when running update-mime-database.";
      };

      desktopFileUtilsPackage = mkOption {
        type = types.package;
        default = pkgs.desktop-file-utils;
        defaultText = lib.literalExpression "pkgs.desktop-file-utils";
        description = "The package to use when running update-desktop-database.";
      };
    };
  };
  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "xdg.mime" pkgs lib.platforms.linux)
    ];

    home.packages = [
      # Explicitly install package to provide basic mime types.
      cfg.sharedMimeInfoPackage

      # Make sure the target directories will be real directories.
      (pkgs.runCommandLocal "dummy-xdg-mime-dirs1" { } ''
        mkdir -p $out/share/{applications,mime/packages}
      '')
      (pkgs.runCommandLocal "dummy-xdg-mime-dirs2" { } ''
        mkdir -p $out/share/{applications,mime/packages}
      '')
    ];

    home.extraProfileCommands = ''
      if [[ -w $out/share/mime && -w $out/share/mime/packages && -d $out/share/mime/packages ]]; then
        XDG_DATA_DIRS=$out/share \
        PKGSYSTEM_ENABLE_FSYNC=0 \
        ${
          getExe (cfg.sharedMimeInfoPackage.__spliced.buildHost or cfg.sharedMimeInfoPackage)
        } -V $out/share/mime > /dev/null
      fi

      if [[ -w $out/share/applications ]]; then
        ${
          getExe' (cfg.desktopFileUtilsPackage.__spliced.buildHost or cfg.desktopFileUtilsPackage
          ) "update-desktop-database"
        } $out/share/applications
      fi
    '';
  };
}
