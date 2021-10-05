{ config, lib, pkgs, ... }:

{
  config = {
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

        assertFileRegex \
          home-path/bin/nnn \
          "^export NNN_BMS='D:~/Downloads;d:~/Documents;p:~/Pictures;v:~/Videos'\''${NNN_BMS:+':'}\$NNN_BMS$"

        assertFileRegex \
          home-path/bin/nnn \
          "^export NNN_PLUG='c:fzcd;f:finder;v:imgview'\''${NNN_PLUG:+':'}\$NNN_PLUG$"

        assertFileRegex \
          home-path/bin/nnn \
          "/nix/store/.*-"{foo,bar}"/bin"
      '';
    };
  };
}
