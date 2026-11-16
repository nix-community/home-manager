{ lib, options, ... }:
{
  imports = [
    {
      programs.notmuch.new.ignore = [ "ordinary" ];
    }
  ];

  programs.mbsync.enable = true;
  programs.lieer.enable = true;
  programs.mujmap.enable = true;
  programs.notmuch = {
    enable = true;
    new.ignore = lib.mkForce [ "private" ];
    extraConfig.user = {
      name = "Sync User";
      primary_email = "sync@example.com";
    };
    settings.new.ignore = lib.mkIf false [ "unused" ];
  };

  test.asserts.warnings.expected = [
    "The option `programs.notmuch.extraConfig' defined in ${lib.showFiles options.programs.notmuch.extraConfig.files} has been renamed to `programs.notmuch.settings'."
    "The option `programs.notmuch.new.ignore' defined in ${lib.showFiles options.programs.notmuch.new.ignore.files} has been renamed to `programs.notmuch.settings.new.ignore'."
  ];

  nmt.script = ''
    assertFileRegex home-files/.config/notmuch/default/config '^ignore=private$'
  '';
}
