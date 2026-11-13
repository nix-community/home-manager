{ lib }:
let
  test =
    astroid: check:
    { pkgs, options, ... }:
    {
      programs.astroid = {
        enable = true;
        package = null;
      }
      // removeAttrs astroid [ "expectedJson" ];

      test.asserts.warnings.expected =
        lib.optional (astroid ? externalEditor)
          "The option `programs.astroid.externalEditor' defined in ${lib.showFiles options.programs.astroid.externalEditor.files} has been changed to `programs.astroid.settings.editor' that has a different type. Please read `programs.astroid.settings.editor' documentation and update your configuration accordingly."
        ++
          lib.optional (astroid ? extraConfig)
            "The option `programs.astroid.extraConfig' defined in ${lib.showFiles options.programs.astroid.extraConfig.files} has been renamed to `programs.astroid.settings'.";

      nmt.script =
        if check == null then
          ''
            assertPathNotExists home-files/.config/astroid/config
          ''
        else
          ''
            assertFileExists home-files/.config/astroid/config
            ${pkgs.jq}/bin/jq -e ${lib.escapeShellArg check} "$TESTED/home-files/.config/astroid/config"
            ${lib.optionalString (
              astroid ? expectedJson
            ) "assertFileContent home-files/.config/astroid/config ${astroid.expectedJson}"}
          '';
    };
in
{
  astroid-legacy-editor =
    test
      {
        externalEditor = "external";
        extraConfig.editor = {
          cmd = lib.mkForce "legacy";
          charset = "ISO-8859-1";
        };
      }
      ''
        . == {"editor": {"cmd": "legacy", "external_editor": "true", "charset": "ISO-8859-1"}}
      '';

  astroid-disabled-editor-definition =
    test
      {
        expectedJson = ./legacy-editor.json;
        externalEditor = "external";
        extraConfig.editor.charset = "ISO-8859-1";
        settings.editor.cmd = lib.mkIf false "disabled";
      }
      ''
        . == {"editor": {"cmd": "external", "external_editor": "true", "charset": "ISO-8859-1"}}
      '';

  astroid-legacy-priorities =
    test
      {
        expectedJson = ./legacy-priorities.json;
        extraConfig = lib.mkMerge [
          {
            poll.interval = lib.mkDefault 0;
            editor.cmd = lib.mkDefault "weak";
            editor.charset = lib.mkIf false "disabled";
            custom.list = lib.mkAfter [ "after" ];
          }
          {
            editor.cmd = lib.mkForce "forced";
            custom.list = lib.mkBefore [ "before" ];
          }
        ];
        settings.poll.interval = lib.mkIf false 30;
      }
      ''
        .poll.interval == 0 and .editor.cmd == "forced"
        and (.editor | has("external_editor") | not)
        and .custom.list == ["before", "after"]
      '';

  astroid-empty-inputs = test {
    externalEditor = null;
    extraConfig = lib.mkForce { };
    settings = { };
  } null;

  astroid-force-settings = test {
    externalEditor = "external";
    extraConfig.poll.interval = lib.mkForce 0;
    settings = lib.mkForce { };
  } null;

  astroid-force-sections = test {
    externalEditor = "external";
    extraConfig.editor.charset = "legacy";
    settings = {
      editor = lib.mkForce { };
      startup = lib.mkForce null;
    };
  } ''. == {"editor": {}, "startup": null}'';
}
