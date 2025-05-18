{
  programs = {
    fish.enable = true;

    starship = {
      enable = true;
      enableInteractive = false;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/fish/config.fish

    export GOT="$(tail -n 5 `_abs home-files/.config/fish/config.fish`)"
    export EXPECTED="
    if test \"\$TERM\" != dumb
        @starship@/bin/starship init fish | source

    end"

    export MESSAGE="
    ==========
     Expected
    ==========
    $EXPECTED
    ==========
       Got
    ==========
    $GOT
    ==========
    "

    if [[ "$GOT" != "$EXPECTED" ]]; then
      fail "$MESSAGE"
    fi
  '';
}
