{ config, ... }: {
  config = {
    programs.xmobar = {
      enable = true;
      package = config.lib.test.mkStubPackage { };
      extraConfig = ''
        Config
          { font        = "Fira Code"
          , borderColor = "#d0d0d0"
          , border      = FullB
          , borderWidth = 3
          , bgColor     = "#222"
          , fgColor     = "grey"
          , position    = TopSize C 99 30
          , commands    =
              [ Run Cpu ["-t", "cpu: <fc=#4eb4fa><bar> <total>%</fc>"] 10
              , Run Network "enp3s0" ["-S", "True", "-t", "eth: <fc=#4eb4fa><rx></fc>/<fc=#4eb4fa><tx></fc>"] 10
              , Run Memory ["-t","mem: <fc=#4eb4fa><usedbar> <usedratio>%</fc>"] 10
              , Run Date "date: <fc=#4eb4fa>%a %d %b %Y %H:%M:%S </fc>" "date" 10
              , Run StdinReader
              ]
          , sepChar     = "%"
          , alignSep    = "}{"
          , template    = "  %StdinReader% | %cpu% | %memory% | %enp3s0%  }{%date%  "
          }
      '';
    };

    nmt.script = ''
      assertFileExists home-files/.config/xmobar/.xmobarrc
      assertFileContent \
        home-files/.config/xmobar/.xmobarrc \
        ${./basic-configuration.expected}
    '';
  };
}
