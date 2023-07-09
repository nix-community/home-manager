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

  i18n-custom-locales = { pkgs, ... }: {
    config = let stub = pkgs.glibcLocalesCustom;
    in {
      test.stubs.glibcLocalesCustom = {
        inherit (pkgs.glibcLocales) version;
        outPath = null; # we need a real path for this stub
      };

      i18n.glibcLocales = stub;

      nmt.script = ''
        hmEnvFile=home-path/etc/profile.d/hm-session-vars.sh
        assertFileExists $hmEnvFile
        assertFileRegex $hmEnvFile 'LOCALE_ARCHIVE_.*${stub}'

        envFile=home-files/.config/environment.d/10-home-manager.conf
        assertFileExists $envFile
        assertFileRegex $envFile 'LOCALE_ARCHIVE_.*${stub}'
      '';
    };
  };
}
