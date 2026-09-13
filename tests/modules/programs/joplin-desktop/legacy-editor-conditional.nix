editor:
{
  config,
  lib,
  options,
  pkgs,
  ...
}:
{
  programs.joplin-desktop = {
    enable = true;
    general.editor = editor;
    extraConfig = lib.mkIf (config.programs.joplin-desktop.general.editor != null) {
      editor = "nano";
      newNoteFocus = "title";
    };
  };

  test.asserts.warnings.expected =
    (import ./warnings.nix { inherit lib options; }) [
      [
        "general"
        "editor"
      ]
    ]
    ++
      lib.optional (editor != null)
        "The option `programs.joplin-desktop.extraConfig' defined in ${lib.showFiles options.programs.joplin-desktop.extraConfig.files} has been renamed to `programs.joplin-desktop.settings'.";

  nmt.script =
    assert config.programs.joplin-desktop.general.editor == editor;
    if editor == null then
      assert config.programs.joplin-desktop.settings == { editor = null; };
      ""
    else
      ''
        generated="$(grep -o '/nix/store/.*-joplin-settings.json' $TESTED/activate)"
        ${pkgs.jq}/bin/jq -e '. == {"editor":"nano","newNoteFocus":"title"}' "$generated"
      '';
}
