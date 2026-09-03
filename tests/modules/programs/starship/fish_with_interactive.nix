{
  imports = [ ./fish-package.nix ];

  programs = {
    fish.enable = true;
    starship.enable = true;
  };

  nmt.script = ''
    assertFileExists home-files/.config/fish/config.fish
    assertFileRegex \
      home-files/.config/fish/config.fish \
      'source /nix/store/[^/]*-starship-fish-config\.fish'
    assertFileNotRegex home-files/.config/fish/config.fish 'starship init fish'

    starshipFishConfig=$(
      sed -n 's|^[[:space:]]*source \(/nix/store/[^ ]*-starship-fish-config\.fish\).*|\1|p' \
        "$TESTED/home-files/.config/fish/config.fish" | head -n1
    )
    assertFileExists "$starshipFishConfig"
    assertFileContains "$starshipFishConfig" \
      'starship fish init args: init fish --print-full-init'

    export GOT="$(tail -n 5 `_abs home-files/.config/fish/config.fish`)"
    export NOT_EXPECTED="
    if test \"\$TERM\" != dumb
        source $starshipFishConfig

    end"

    if [[ "$GOT" == "$NOT_EXPECTED" ]]; then
      fail "Expected starship init to be inside the 'is-interactive' block but it wasn't."
    fi
  '';
}
