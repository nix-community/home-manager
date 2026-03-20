{
  config = {
    programs.gcc = {
      enable = true;
    };

    nmt.script = ''
      # Verify no GCC_COLORS environment variable is set when colors is empty
      hmEnvFile=home-path/etc/profile.d/hm-session-vars.sh
      assertFileNotRegex $hmEnvFile 'GCC_COLORS'
    '';
  };
}
