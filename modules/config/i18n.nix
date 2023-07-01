# The glibc package in Nixpkgs is patched to make it possible to specify
# an alternative path for the locale archive through a special environment
# variable. This would allow different versions of glibc to coexist on the
# same system because each version of glibc could look up different paths
# for its locale archive should the archive format ever change in
# incompatible ways.
#
# See also:
# - localedef(1)
# - https://nixos.org/manual/nixpkgs/stable/#locales
# - https://github.com/NixOS/nixpkgs/issues/38991
#
# Note, the name of the said environment variable gets updated with each
# breaking release of the glibcLocales package. Periodically check the link
# below for changes:
# https://github.com/NixOS/nixpkgs/blob/nixpkgs-unstable/pkgs/development/libraries/glibc/nix-locale-archive.patch

{ lib, pkgs, config, ... }:

with lib;

let
  inherit (config.i18n) glibcLocales;

  inherit (glibcLocales) version;

  archivePath = "${glibcLocales}/lib/locale/locale-archive";

  # lookup the version of glibcLocales and set the appropriate environment vars
  localeVars = if versionAtLeast version "2.27" then {
    LOCALE_ARCHIVE_2_27 = archivePath;
  } else if versionAtLeast version "2.11" then {
    LOCALE_ARCHIVE_2_11 = archivePath;
  } else
    { };

in {
  meta.maintainers = with maintainers; [ midchildan ];

  options = {
    i18n.glibcLocales = mkOption {
      type = types.path;
      description = ''
        Customized `glibcLocales` package providing
        the `LOCALE_ARCHIVE_*` environment variable.

        This option only applies to the Linux platform.

        When Home Manager is configured with NixOS, the default value
        will be set to {var}`i18n.glibcLocales` from the
        system configuration.
      '';
      example = literalExpression ''
        pkgs.glibcLocales.override {
          allLocales = false;
          locales = [ "en_US.UTF-8/UTF-8" ];
        }
      '';
      # NB. See nixos/default.nix for NixOS default.
      default = pkgs.glibcLocales;
      defaultText = literalExpression "pkgs.glibcLocales";
    };
  };

  config = mkIf pkgs.stdenv.hostPlatform.isLinux {
    # For shell sessions.
    home.sessionVariables = localeVars;

    # For desktop apps.
    systemd.user.sessionVariables = localeVars;
  };
}
