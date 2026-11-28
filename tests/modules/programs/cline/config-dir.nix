{ config, ... }:
{
  programs.cline = {
    enable = true;
    package = null;
    configDir = "${config.xdg.configHome}/cline";
    settings.telemetryOptOut = true;
  };

  nmt.script = ''
    assertPathNotExists home-files/.cline

    assertFileExists home-files/.config/cline/data/settings/global-settings.json

    assertFileRegex home-path/etc/profile.d/hm-session-vars.sh \
      'export CLINE_DIR="/home/hm-user/.config/cline"'
    assertFileRegex home-path/etc/profile.d/hm-session-vars.sh \
      'export CLINE_KANBAN_DATA_DIR="/home/hm-user/.config/cline/apps/kanban"'
  '';
}
