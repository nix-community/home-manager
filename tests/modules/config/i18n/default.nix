{
  i18n = { ... }: {
    config = {
      nmt.script = ''
        hmEnvFile=home-path/etc/profile.d/hm-session-vars.sh
        assertFileExists $hmEnvFile
        assertFileRegex $hmEnvFile \
          '^export LOCALE_ARCHIVE_._..=".*/lib/locale/locale-archive"$'

        envFile=home-files/.config/environment.d/10-home-manager.conf
        assertFileExists $envFile
        assertFileRegex $envFile \
          '^LOCALE_ARCHIVE_._..=.*/lib/locale/locale-archive$'
      '';
    };
  };

  i18n-custom-locales = { config, pkgs, ... }: {
    config = let
      customGlibcLocales = pkgs.glibcLocales.override {
        allLocales = false;
        locales = [ "en_US.UTF-8/UTF-8" ];
      };
    in {
      i18n.glibcLocales = customGlibcLocales;

      nmt.script = ''
        hmEnvFile=home-path/etc/profile.d/hm-session-vars.sh
        assertFileExists $hmEnvFile
        assertFileRegex $hmEnvFile 'LOCALE_ARCHIVE_.*${customGlibcLocales}'

        envFile=home-files/.config/environment.d/10-home-manager.conf
        assertFileExists $envFile
        assertFileRegex $envFile 'LOCALE_ARCHIVE_.*${customGlibcLocales}'
      '';
    };
  };
}
