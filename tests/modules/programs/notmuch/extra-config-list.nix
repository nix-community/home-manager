{
  config,
  lib,
  options,
  ...
}:
{
  programs.notmuch = {
    enable = true;
    new.ignore = [ "modeled" ];
    new.tags = lib.mkForce [ "forced" ];
    extraConfig.new.ignore = [ "overlay" ];
    extraConfig.new.tags = "overlaid";
    settings.user = {
      name = "List Merge";
      primary_email = "list@example.com";
    };
  };

  assertions = [
    {
      assertion =
        lib.sort builtins.lessThan config.programs.notmuch.settings.new.ignore == [
          "modeled"
          "overlay"
        ];
      message = "List definitions through extraConfig must concatenate.";
    }
  ];

  test.asserts.warnings.expected = [
    "The option `programs.notmuch.extraConfig' defined in ${lib.showFiles options.programs.notmuch.extraConfig.files} has been renamed to `programs.notmuch.settings'."
    "The option `programs.notmuch.new.tags' defined in ${lib.showFiles options.programs.notmuch.new.tags.files} has been renamed to `programs.notmuch.settings.new.tags'."
    "The option `programs.notmuch.new.ignore' defined in ${lib.showFiles options.programs.notmuch.new.ignore.files} has been renamed to `programs.notmuch.settings.new.ignore'."
  ];

  nmt.script = ''
    assertFileContains home-files/.config/notmuch/default/config 'ignore=${lib.concatStringsSep ";" config.programs.notmuch.settings.new.ignore}'
    assertFileRegex home-files/.config/notmuch/default/config '^tags=forced$'
  '';
}
