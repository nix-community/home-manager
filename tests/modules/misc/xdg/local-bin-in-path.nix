{
  xdg.enable = true;
  xdg.localBinInPath = true;

  nmt.script = ''
    assertFileExists home-path/etc/profile.d/hm-session-vars.sh
    assertFileContains home-path/etc/profile.d/hm-session-vars.sh \
      '__hm_entry="/home/hm-user/.local/bin"'
    assertFileContains home-path/etc/profile.d/hm-session-vars.sh \
      '__hm_cur="''${PATH-}"'
    # Each value must be prepended, not appended. Checked inside that
    # variable's own merge block: on Darwin the terminfo fallback adds a
    # genuine append block elsewhere in the same file.
    grep -B 3 -F 'export PATH="$__hm_cur"' "$TESTED/home-path/etc/profile.d/hm-session-vars.sh" \
      | grep -qF '__hm_cur="$__hm_add' \
      || fail 'PATH must be prepended, not appended'
  '';
}
