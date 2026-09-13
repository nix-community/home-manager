{
  config,
  lib,
  options,
  pkgs,
  ...
}:
{
  imports = [
    { programs.joplin-desktop.settings = lib.mkDefault { nested.composed = true; }; }
  ];
  programs.joplin-desktop = {
    enable = true;
    settings = lib.mkDefault {
      "sync.target" = 7;
      "sync.interval" = 600;
      "richTextBannerDismissed" = true;
      "newNoteFocus" = "title";
      editor = "";
      omitted = null;
      falseValue = false;
      zeroValue = 0;
      emptyList = [ ];
      emptyObject = { };
      nested = {
        empty = "";
        nullValue = null;
      };
    };
  };

  nmt.script =
    assert config.programs.joplin-desktop.general.editor == "";
    assert config.programs.joplin-desktop.sync.target == "undefined";
    assert config.programs.joplin-desktop.sync.interval == "undefined";
    assert options.programs.joplin-desktop.settings.default == { };
    assert !options.programs.joplin-desktop.general.editor.visible;
    assert !options.programs.joplin-desktop.sync.target.visible;
    assert !options.programs.joplin-desktop.sync.interval.visible;
    assert !options.programs.joplin-desktop.extraConfig.visible;
    ''
      assertFileContains activate \
        '/home/hm-user/.config/joplin-desktop/settings.json'

      generated="$(grep -o '/nix/store/.*-joplin-settings.json' $TESTED/activate)"
      diff -u "$generated" ${./basic-configuration.json}

      assertPathNotExists home-files/.config/joplin-desktop/settings.json
      mkdir -p profile
      printf '%s\n' '{"unmanaged":"keep","editor":"existing","omitted":23,"newNoteFocus":"body"}' > profile/settings.json
      export PATH=${lib.makeBinPath [ pkgs.jq ]}:$PATH
      ${pkgs.writeShellScript "test-joplin-merge" (
        lib.replaceStrings
          [ "/home/hm-user/.config/joplin-desktop/settings.json" ]
          [ "$PWD/profile/settings.json" ]
          config.home.activation.activateJoplinDesktopConfig.data
      )}
      test ! -L profile/settings.json
      ${pkgs.jq}/bin/jq -e --slurpfile generated "$generated" \
        '. == ({"unmanaged":"keep","editor":"existing","omitted":23} + $generated[0])' profile/settings.json
    '';
}
