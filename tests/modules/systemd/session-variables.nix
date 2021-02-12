{ config, lib, pkgs, ... }:

{
  config = {
    systemd.user.sessionVariables = {
      V_int = 1;
      V_str = "2";
    };

    nmt.script = ''
      envFile=home-files/.config/environment.d/10-home-manager.conf
      assertFileExists $envFile
      assertFileContent $envFile ${pkgs.writeText "expected" ''
        LOCALE_ARCHIVE_2_27=${pkgs.glibcLocales}/lib/locale/locale-archive
        V_int=1
        V_str=2
      ''}

      sessionVarsFile=home-path/etc/profile.d/hm-session-vars.sh
      assertFileExists $sessionVarsFile
      assertFileContains $sessionVarsFile \
        'export $(${pkgs.systemd}/lib/systemd/user-environment-generators/30-systemd-environment-d-generator)'
    '';
  };
}
