{ config, ... }:

{
  programs.claude-code = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "claude-code";
      version = "2.1.157";
      buildScript = ''
        mkdir -p $out/bin
        touch $out/bin/claude
        chmod 755 $out/bin/claude
      '';
    };
    plugins.test = ./test-plugin;
    skills = ./skills-path-not-directory.nix;
  };

  home.file."${config.programs.claude-code.configDir}/skills".enable = false;

  test.asserts.assertions.expected = [
    "`programs.claude-code.skills` must be a directory when set to a path"
  ];
}
