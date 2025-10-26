{
  programs.grep = {
    enable = true;
    colors = {
      error = "01;31";
      match = "01;32";
    };
  };

  nmt.script = ''
    # Check that grep colors are set in session variables
    assertFileContains home-path/etc/profile.d/hm-session-vars.sh \
      'export GREP_COLORS="error=01;31:match=01;32"'
  '';
}
