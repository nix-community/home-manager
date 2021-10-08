{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.xdg.mime;

in {
  options = {
    xdg.mime.enable = mkOption {
      type = types.bool;
      default = pkgs.hostPlatform.isLinux;
      defaultText =
        literalExpression "true if host platform is Linux, false otherwise";
      description = ''
        Whether to install programs and files to support the
        XDG Shared MIME-info specification and XDG MIME Applications
        specification at
        <link xlink:href="https://specifications.freedesktop.org/shared-mime-info-spec/shared-mime-info-spec-latest.html"/>
        and
        <link xlink:href="https://specifications.freedesktop.org/mime-apps-spec/mime-apps-spec-latest.html"/>,
        respectively.
      '';
    };
  };

  config = mkIf config.xdg.mime.enable {
    assertions =
      [ (hm.assertions.assertPlatform "xdg.mime" pkgs platforms.linux) ];

    home.packages = [
      # Explicitly install package to provide basic mime types.
      pkgs.shared-mime-info

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
        ${pkgs.buildPackages.shared-mime-info}/bin/update-mime-database \
          -V $out/share/mime > /dev/null
      fi

      if [[ -w $out/share/applications ]]; then
        ${pkgs.buildPackages.desktop-file-utils}/bin/update-desktop-database \
          $out/share/applications
      fi
    '';
  };

}
