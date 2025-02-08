{ config, pkgs, ... }:

{
  config = {
    programs.eww = {
      enable = true;
      systemd.enable = true;
      yuckConfig = ''
        (defwindow example
             :monitor 0
             :geometry (geometry :x "0%"
                                 :y "20px"
                                 :width "90%"
                                 :height "30px"
                                 :anchor "top center")
             :stacking "fg"
             :reserve (struts :distance "40px" :side "top")
             :windowtype "dock"
             :wm-ignore false
          "example content")
      '';
      scssConfig = ''
        window {
          background: pink;
        }
      '';
    };

    test.stubs.eww = { name = "eww"; };

    nmt.script = ''
      assertFileExists home-files/.config/eww/eww.yuck
      assertFileExists home-files/.config/eww/eww.scss
      serviceFile=$(normalizeStorePaths home-files/.config/systemd/user/eww.service)
      assertFileContent "$serviceFile" ${./basic-configuration.service}
    '';
  };
}
