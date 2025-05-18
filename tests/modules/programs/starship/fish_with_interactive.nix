{
  programs = {
    fish.enable = true;
    starship.enable = true;
  };

  nmt.script = ''
    assertFileExists home-files/.config/fish/config.fish

    export GOT="$(tail -n 5 `_abs home-files/.config/fish/config.fish`)"
    export NOT_EXPECTED="
    if test \"\$TERM\" != dumb
        @starship@/bin/starship init fish | source

    end"

    if [[ "$GOT" == "$NOT_EXPECTED" ]]; then
      fail "Expected starship init to be inside the 'is-interactive' block but it wasn't."
    fi
  '';
}
