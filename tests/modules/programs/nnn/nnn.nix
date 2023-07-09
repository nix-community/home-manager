{ pkgs, ... }:

{
  programs.nnn = {
    enable = true;
    bookmarks = {
      d = "~/Documents";
      D = "~/Downloads";
      p = "~/Pictures";
      v = "~/Videos";
    };
    package = pkgs.nnnDummy;
    extraPackages = with pkgs; [ foo bar ];
    plugins = {
      src = ./plugins;
      mappings = {
        c = "fzcd";
        f = "finder";
        v = "imgview";
      };
    };
  };

  test.stubs = {
    nnnDummy.buildScript = ''
      runHook preInstall

      mkdir -p "$out/bin"
      touch "$out/bin/nnn"
      chmod +x "$out/bin/nnn"

      runHook postInstall
    '';
    foo = { name = "foo"; };
    bar = { name = "bar"; };
  };

  nmt = {
    description =
      "Check if the binary is correctly wrapped and if the symlinks are made";
    script = ''
      assertDirectoryExists home-files/.config/nnn/plugins

      for bookmark in 'export NNN_BMS' '~/Downloads' '~/Documents' '~/Pictures' '~/Videos'; do
        assertFileRegex home-path/bin/nnn "$bookmark"
      done

      for plugin in 'export NNN_PLUG' 'fzcd' 'finder' 'imgview'; do
        assertFileRegex home-path/bin/nnn "$plugin"
      done
    '';
  };
}
