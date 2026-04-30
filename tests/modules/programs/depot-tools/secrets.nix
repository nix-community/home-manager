{
  config,
  lib,
  ...
}:

{
  options.age.secrets = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.path = lib.mkOption {
          type = lib.types.str;
        };
      }
    );
    default = { };
  };

  config = {
    programs.bash.enable = true;
    programs.zsh.enable = true;

    programs.depot-tools = {
      enable = true;
      environment.DEPOT_TOOLS_METRICS = "0";
      environmentSecretFiles = {
        GIT_COOKIES_PATH = config.age.secrets.chromium-git-cookies.path;
        LUCI_CONTEXT = config.age.secrets.luci-context.path;
      };
    };

    age.secrets = {
      chromium-git-cookies.path = "/run/agenix/chromium-git-cookies";
      luci-context.path = "/run/agenix/luci-context";
    };

    test.stubs.depot-tools = { };

    nmt.script = ''
      service=home-files/.config/systemd/user/depot-tools-environment.service

      assertFileExists "$service"
      assertFileRegex "$service" 'After=agenix.service'
      assertFileRegex "$service" 'Requires=agenix.service'
      assertFileRegex "$service" 'ExecStart=.*/bin/depot-tools-environment'

      assertFileExists home-files/.bashrc
      assertFileRegex home-files/.bashrc '.*/depot-tools/environment'

      assertFileExists home-files/.zshrc
      assertFileRegex home-files/.zshrc '.*/depot-tools/environment'
    '';
  };
}
