{ ... }:

let
  shellIntegration = ''
    function ya
      set tmp (mktemp -t "yazi-cwd.XXXXX")
      yazi --cwd-file="$tmp"
      if set cwd (cat -- "$tmp") && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]
        cd -- "$cwd"
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
