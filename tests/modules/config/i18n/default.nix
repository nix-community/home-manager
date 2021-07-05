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
}
