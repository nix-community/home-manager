{ config, lib, pkgs, ... }:

with lib;

let
  inherit (pkgs.stdenv.hostPlatform) isLinux;

  expectedConf = pkgs.substituteAll {
    src = ./session-variables-expected.txt;
    # the blank space below is intentional
    exportLocaleVar = optionalString isLinux ''

      export LOCALE_ARCHIVE_2_27="${pkgs.glibcLocales}/lib/locale/locale-archive"'';
  };
in {
  config = {
    home.sessionVariables = {
      V1 = "v1";
      V2 = "v2-${config.home.sessionVariables.V1}";
    };

    nmt.script = ''
      assertFileExists home-path/etc/profile.d/hm-session-vars.sh
      assertFileContent home-path/etc/profile.d/hm-session-vars.sh \
        ${expectedConf}
    '';
  };
}
