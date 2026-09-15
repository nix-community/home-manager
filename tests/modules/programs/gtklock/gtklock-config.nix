{ pkgs, ... }:
{
  programs.gtklock = {
    enable = true;
    settings.main = {
      idle-hide = true;
      idle-timeout = 60;
      start-hidden = true;
    };
    modulePackages = [
      (pkgs.writeTextDir "lib/gtklock/module_1.so" "")
      (pkgs.runCommand "gtklock-module" { } ''
        mkdir -p $out/lib/gtklock
        touch $out/lib/gtklock/module_2.so
        touch $out/lib/gtklock/module_3.so
        touch $out/lib/gtklock/readme.txt
      '')
    ];
    background.path = builtins.toFile "background.jpg" "";
  };

  nmt.script = ''
    configPath=home-files/.config/gtklock/config.ini
    configFile=$(normalizeStorePaths "$configPath")
    assertFileContent "$configFile" ${./gtklock-expected-config.ini}

    stylePath=$(grep '^style=' "$TESTED/home-files/.config/gtklock/config.ini" | sed 's/^style=//')
    styleFile=$(normalizeStorePaths "$stylePath")
    assertFileContent "$styleFile" ${./gtklock-expected-style.css}
  '';
}
