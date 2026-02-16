{
  config = {
    programs.grep = {
      enable = true;
    };

    nmt.script = ''
      # Verify no GREP_COLORS environment variable is set when colors is empty
      hmEnvFile=home-path/etc/profile.d/hm-session-vars.sh
      assertFileNotRegex $hmEnvFile 'GCC_COLORS'
    '';
  };
}
