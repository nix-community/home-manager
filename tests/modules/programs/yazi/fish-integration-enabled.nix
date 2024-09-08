{ ... }:

let
  shellIntegration = ''
    function yy
      set tmp (mktemp -t "yazi-cwd.XXXXX")
      yazi $argv --cwd-file="$tmp"
      if set cwd (cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
        builtin cd -- "$cwd"
      end
      rm -f -- "$tmp"
    end
  '';
in {
  programs.fish.enable = true;

  programs.yazi = {
    enable = true;
    enableFishIntegration = true;
  };

  test.stubs.yazi = { };

  nmt.script = ''
    assertFileContains home-files/.config/fish/config.fish '${shellIntegration}'
  '';
}
