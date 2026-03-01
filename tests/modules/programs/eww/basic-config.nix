{
  config = {
    programs.eww = {
      enable = true;
      systemd.enable = true;
      yuckConfig = ''
              (defwindow powermenu
            :monitor 0
            :geometry (geometry
                :anchor "center"
            )
            ; Widgets
            (box
                :spacing 5
                :class "powermenu"
                :space-evenly true
                :orientation "vertical"
                :halign "left"
                :valign "center"

                ; Contents
                (button
                    :onclick "eww open confirm-command --arg action=poweroff --arg command=poweroff"
                    "Poweroff"
                )
                (button
                    :onclick "eww open confirm-command --arg action=reboot --arg command=reboot"
                    "Reboot"
                )
                (button
                    :onclick "eww close powermenu"
                    "Cancel"
                )
            )
        )

        (defwindow confirm-command [action command]
            :monitor 0
            :geometry (geometry
                :anchor "center"
                :width "13%"
                :height "8%"
            )
            ; Widgets
            (box
                :class "powermenu"
                :orientation "vertical"
                :halign "center"
                :valign "center"
                "Are you sure you want to ''${action}"
                (box
                    :orientation "horizontal"
                    :spacing 10
                    (button
                        :onclick "eww close confirm-command"
                        "No"
                    )
                    (button
                        :onclick command
                        "Yes"
                    )
                )
            )
        )
      '';
      scssConfig = ''
                .powermenu {
          padding: 10px 10px;
          border-radius: 10px;
        }
      '';
    };

    nmt.script = ''
      yuckDir=home-files/.config/eww
      serviceFile=$(normalizeStorePaths home-files/.config/systemd/user/eww.service)

      assertFileExists $yuckDir/eww.yuck
      assertFileExists $yuckDir/eww.scss

      assertFileContent $yuckDir/eww.yuck ${./expected.yuck}
      assertFileContent $yuckDir/eww.scss ${./expected.scss}
      assertFileContent "$serviceFile" ${./expected.service}
    '';
  };
}
