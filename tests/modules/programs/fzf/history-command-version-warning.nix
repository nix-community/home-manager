{
  config,
  lib,
  options,
  ...
}:

{
  programs.fzf = {
    enable = true;
    enableNushellIntegration = false;

    historyWidget.command = "history";

    package = config.lib.test.mkStubPackage {
      name = "fzf";
      version = "0.65.0";
    };
  };

  test.asserts.warnings.expected = [
    ''
      `programs.fzf.historyWidget.command` defined in ${lib.showFiles options.programs.fzf.historyWidget.command.files} requires fzf 0.66.0 or greater.

      The configured FZF_CTRL_R_COMMAND value will be ignored by older fzf
      versions.
    ''
  ];

  nmt.script = ''
    assertFileExists home-path/etc/profile.d/hm-session-vars.sh
  '';
}
