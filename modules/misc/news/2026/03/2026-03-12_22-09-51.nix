{ config, ... }:
{
  time = "2026-03-13T03:09:51+00:00";
  condition = config.programs.gemini-cli.enable;
  message = ''
    The `programs.gemini-cli.policies` option has been added to support configuring
    the Gemini CLI policy engine.

    This option accepts an attribute set where values can either be paths to existing
    TOML files or attribute sets that will be generated into TOML format. These
    policies provide fine-grained control over tool execution rules for the CLI.
  '';
}
