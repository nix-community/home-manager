{ config, ... }:

{
  time = "2025-12-12T19:20:28+00:00";
  condition = config.xsession.windowManager.herbstluftwm.enable;
  message = ''
    It is now possible to disable the `herbstclient` alias in the autostart
    script by setting `xsession.windowManagers.herbsluftwm.enableAlias = false`.
    This makes it possible to use the `herbstclient` command in bash functions,
    though may cause flickering while the autostart script runs.
  '';
}
