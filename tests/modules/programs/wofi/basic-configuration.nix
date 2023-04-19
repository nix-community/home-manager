{ pkgs, ... }:

{
  config = {
    programs.wofi = {
      enable = true;
      package = pkgs.writeScriptBin "dummy-wofi" "";
      style = ''
        * {
            font-family: monospace;
        }
        window {
            background-color: #7c818c;
        }
      '';
      settings = {
        drun-print_command = true;
        insensitive = true;
        show = "drun";
        xoffset = 50;
        yoffset = 200;
      };
    };

    nmt.script = ''
      assertFileExists home-files/.config/wofi/config
      assertFileContent home-files/.config/wofi/config \
          ${./basic-configuration.conf}

      assertFileExists home-files/.config/wofi/style.css
      assertFileContent home-files/.config/wofi/style.css \
          ${./basic-style.css}
    '';
  };
}
