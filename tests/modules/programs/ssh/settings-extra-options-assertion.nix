{ lib, options, ... }:
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings.legacy.extraOptions = {
      AddKeysToAgent = "yes";
      HostName = "example.org";
    };
  };

  test.asserts.assertions.expected = [
    ''
      `programs.ssh.settings.*.extraOptions` defined in ${lib.showFiles options.programs.ssh.settings.files} is not supported. Move these OpenSSH options directly into `programs.ssh.settings.*` using upstream directive names.
    ''
  ];
}
