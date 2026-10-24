{ realPkgs, ... }:
{
  programs.radare2 = {
    enable = true;
    settings = {
      "scr.color" = 2;
      "scr.utf8" = true;
      "asm.describe" = false;
      "cmd.prompt" = "px;s+1";
      "cmd.vprompt" = ''?e "quoted";?e \path\;?e `s+1` $(s+1) @ 1 | s+1 ~ x # x'';
      "cmd.cprompt" = "trailing\\";
    };
    extraConfig = ''
      eco bobcrawl
    '';
  };

  nmt.script = ''
    assertFileContent "home-files/.config/radare2/rc" ${./expected-rc}
    assertPathNotExists "home-files/.config/radare2/radare2rc"

    # Loading settings must preserve command-valued strings without running them.
    actual=$(${realPkgs.radare2}/bin/radare2 -N -q \
      -i "$TESTED/home-files/.config/radare2/rc" \
      -c 'e cmd.prompt' -c 'e cmd.vprompt' -c 'e cmd.cprompt' -c s -c q malloc://16)
    expected=$(printf '%s\n' \
      'px;s+1' \
      '?e "quoted";?e \path\;?e `s+1` $(s+1) @ 1 | s+1 ~ x # x' \
      'trailing\' \
      '0x0')
    [[ "$actual" == "$expected" ]] || fail "settings changed or executed during startup"
  '';
}
