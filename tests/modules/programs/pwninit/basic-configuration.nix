{ config, ... }: {
  config = {
    programs.bash.enable = true;

    programs.pwninit = {
      enable = true;
      package = config.lib.test.mkStubPackage { };
      template = "A simple test";
      templateAlias = true;
    };

    nmt.script = ''
      assertFileRegex home-files/.bashrc \
        'pwninit --template-path.*template.py'
    '';
  };
}
