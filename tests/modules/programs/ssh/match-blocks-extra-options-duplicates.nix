{
  config,
  lib,
  options,
  ...
}:
{
  config = {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks.legacy = {
        user = "typed-user";
        hostname = "example.org";
        extraOptions = {
          ForwardAgent = "yes";
          HostName = "extra.example.org";
          User = "extra-user";
        };
      };
    };

    home.file.assertions.text = builtins.toJSON (
      map (a: a.message) (lib.filter (a: !a.assertion) config.assertions)
    );

    test.asserts.warnings.expected = [
      ''
        `programs.ssh.matchBlocks` defined in ${lib.showFiles options.programs.ssh.matchBlocks.files} is deprecated. Use `programs.ssh.settings`.
      ''
      ''
        `programs.ssh.matchBlocks.legacy.extraOptions` defined in ${lib.showFiles options.programs.ssh.matchBlocks.files} is deprecated. Move these OpenSSH options to `programs.ssh.settings.legacy` using upstream directive names.
      ''
    ];

    nmt.script = ''
      assertFileExists home-files/.ssh/config
      assertFileContent \
        home-files/.ssh/config \
        ${./match-blocks-extra-options-duplicates-expected.conf}
      assertFileContent home-files/assertions ${./no-assertions.json}
    '';
  };
}
