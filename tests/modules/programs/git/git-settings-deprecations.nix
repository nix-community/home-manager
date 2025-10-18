{ lib, options, ... }:

{
  programs.git = {
    enable = true;
    userName = "John Doe";
    userEmail = "john@example.com";
    aliases = {
      co = "checkout";
      st = "status";
    };
  };

  test.asserts.warnings.expected = [
    "The option `programs.git.aliases' defined in ${lib.showFiles options.programs.git.aliases.files} has been renamed to `programs.git.settings.alias'."
    "The option `programs.git.userEmail' defined in ${lib.showFiles options.programs.git.userEmail.files} has been renamed to `programs.git.settings.user.email'."
    "The option `programs.git.userName' defined in ${lib.showFiles options.programs.git.userName.files} has been renamed to `programs.git.settings.user.name'."
  ];

  nmt.script = ''
    assertFileExists home-files/.config/git/config
    assertFileContains home-files/.config/git/config '[alias]'
    assertFileContains home-files/.config/git/config 'co = "checkout"'
    assertFileContains home-files/.config/git/config 'st = "status"'
    assertFileContains home-files/.config/git/config '[user]'
    assertFileContains home-files/.config/git/config 'email = "john@example.com"'
    assertFileContains home-files/.config/git/config 'name = "John Doe"'
  '';
}
