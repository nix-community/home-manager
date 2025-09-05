{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.programs.anki;
  # This script generates the Anki SQLite settings DB using the Anki Python API.
  # The configuration options in the SQLite database take the form of Python
  # Pickle data.
  # A simple "gldriver6" file is also generated for the `videoDriver` option.
  buildAnkiConfig = pkgs.writers.writeText "buildAnkiConfig" ''
    import sys

    from aqt.profiles import ProfileManager, VideoDriver
    from aqt.theme import Theme, WidgetStyle, theme_manager
    from aqt.toolbar import HideMode

    profile_manager = ProfileManager(
      ProfileManager.get_created_base_folder(sys.argv[1])
    )
    _ = profile_manager.setupMeta()
    profile_manager.meta["firstRun"] = False

    # Video driver. Option is stored in a separate file from other options.
    video_driver_str: str = "${toString cfg.videoDriver}"
    if video_driver_str:
      # The enum value for OpenGL isn't "opengl"
      if video_driver_str == "opengl":
        video_driver = VideoDriver.OpenGL
      else:
        video_driver = VideoDriver(video_driver_str)
      profile_manager.set_video_driver(video_driver)


    # Shared options

    profile_manager.setLang("${cfg.language}")

    theme_str: str = "${toString cfg.theme}"
    if theme_str:
      theme: Theme = {
        "followSystem": Theme.FOLLOW_SYSTEM,
        "light": Theme.LIGHT,
        "dark": Theme.DARK
      }[theme_str]
      profile_manager.set_theme(theme)

    style_str: str = "${toString cfg.style}"
    if style_str:
      style: WidgetStyle = {
        "anki": WidgetStyle.ANKI, "native": WidgetStyle.NATIVE
      }[style_str]
      # Fix error from there being no main window to update the style of
      theme_manager.apply_style = lambda: None
      profile_manager.set_widget_style(style)

    ui_scale_str: str = "${toString cfg.uiScale}"
    if ui_scale_str:
      profile_manager.setUiScale(float(ui_scale_str))

    hide_top_bar_str: str = "${toString cfg.hideTopBar}"
    if hide_top_bar_str:
      profile_manager.set_hide_top_bar(bool(hide_top_bar_str))

    hide_top_bar_mode_str: str = "${toString cfg.hideTopBarMode}"
    if hide_top_bar_mode_str:
      hide_mode: HideMode = {
        "fullscreen": HideMode.FULLSCREEN,
        "always": HideMode.ALWAYS,
      }[hide_top_bar_mode_str]
      profile_manager.set_top_bar_hide_mode(hide_mode)

    hide_bottom_bar_str: str = "${toString cfg.hideBottomBar}"
    if hide_bottom_bar_str:
      profile_manager.set_hide_bottom_bar(bool(hide_bottom_bar_str))

    hide_bottom_bar_mode_str: str = "${toString cfg.hideBottomBarMode}"
    if hide_bottom_bar_mode_str:
      hide_mode: HideMode = {
        "fullscreen": HideMode.FULLSCREEN,
        "always": HideMode.ALWAYS,
      }[hide_bottom_bar_mode_str]
      profile_manager.set_bottom_bar_hide_mode(hide_mode)

    reduce_motion_str: str = "${toString cfg.reduceMotion}"
    if reduce_motion_str:
      profile_manager.set_reduce_motion(bool(reduce_motion_str))

    minimalist_mode_str: str = "${toString cfg.minimalistMode}"
    if minimalist_mode_str:
      profile_manager.set_minimalist_mode(bool(minimalist_mode_str))

    spacebar_rates_card_str: str = "${toString cfg.spacebarRatesCard}"
    if spacebar_rates_card_str:
      profile_manager.set_spacebar_rates_card(bool(spacebar_rates_card_str))

    legacy_import_export_str: str = "${toString cfg.legacyImportExport}"
    if legacy_import_export_str:
      profile_manager.set_legacy_import_export(bool(legacy_import_export_str))

    answer_keys: tuple[tuple[int, str], ...] = (${
      lib.strings.concatMapStringsSep ", " (val: "(${toString val.ease}, '${val.key}')") cfg.answerKeys
    })
    for ease, key in answer_keys:
      profile_manager.set_answer_key(ease, key)

    # Profile specific options

    profile_manager.create("User 1")
    profile_manager.openProfile("User 1")

    # Without this, the collection DB won't get automatically optimized.
    profile_manager.profile["lastOptimize"] = None

    auto_sync_str: str = "${toString cfg.sync.autoSync}"
    if auto_sync_str:
      profile_manager.profile["autoSync"] = bool(auto_sync_str)

    sync_media_str: str = "${toString cfg.sync.syncMedia}"
    if sync_media_str:
      profile_manager.profile["syncMedia"] = bool(sync_media_str)

    media_sync_minutes_str: str = "${toString cfg.sync.autoSyncMediaMinutes}"
    if media_sync_minutes_str:
      profile_manager.set_periodic_sync_media_minutes = int(media_sync_minutes_str)

    network_timeout_str: str = "${toString cfg.sync.networkTimeout}"
    if network_timeout_str:
      profile_manager.set_network_timeout = int(network_timeout_str)

    profile_manager.save()
  '';
in
{
  ankiConfig =
    let
      cfgAnkiPython = (
        lib.lists.findSingle (x: x.isPy3 or false) null null (cfg.package.nativeBuildInputs or [ ])
      );
      ankiPackage = if cfgAnkiPython == null then pkgs.anki else cfg.package;
      ankiPython = if cfgAnkiPython == null then pkgs.python3 else cfgAnkiPython;
    in
    pkgs.runCommand "ankiConfig"
      {
        nativeBuildInputs = [ ankiPackage ];
      }
      ''
        ${ankiPython.interpreter} ${buildAnkiConfig} $out
      '';

  # An Anki add-on is used for sync settings, so the secrets can be
  # retrieved at runtime.
  syncConfigAnkiAddon = pkgs.anki-utils.buildAnkiAddon {
    pname = "hm-sync-config";
    version = "1.0";
    src = pkgs.writeTextDir "__init__.py" ''
      import aqt
      from pathlib import Path

      username: str | None = ${if cfg.sync.username == null then "None" else "'${cfg.sync.username}'"}
      username_file: Path | None = ${
        if cfg.sync.usernameFile == null then "None" else "Path('${cfg.sync.usernameFile}')"
      }
      key_file: Path | None = ${
        if cfg.sync.passwordFile == null then "None" else "Path('${cfg.sync.passwordFile}')"
      }
      custom_sync_url: str | None = ${if cfg.sync.url == null then "None" else "'${cfg.sync.url}'"}

      def set_server() -> None:
          if custom_sync_url:
            aqt.mw.pm.set_custom_sync_url(custom_sync_url)
          if username:
            aqt.mw.pm.set_sync_username(username)
          elif username_file and username_file.exists():
              aqt.mw.pm.set_sync_username(username_file.read_text())
          if key_file and key_file.exists():
              aqt.mw.pm.set_sync_key(key_file.read_text())

      aqt.gui_hooks.profile_did_open.append(set_server)
    '';
  };

  # Make Anki work better with declarative settings. See script for specific changes.
  homeManagerAnkiAddon = pkgs.anki-utils.buildAnkiAddon {
    pname = "home-manager";
    version = "1.0";
    src = pkgs.writeTextDir "__init__.py" ''
      import aqt
      from aqt.qt import QWidget, QMessageBox
      from anki.hooks import wrap
      from typing import Any

      def make_config_differences_str(initial_config: dict[str, Any],
                                      new_config: dict[str, Any]) -> str:
        details = ""
        for key, val in new_config.items():
            initial_val = initial_config.get(key)
            if val != initial_val:
              details += f"{key} changed from `{initial_val}` to `{val}`\n"
        return details

      def dialog_did_open(dialog_manager: aqt.DialogManager,
                          dialog_name: str,
                          dialog_instance: QWidget) -> None:
        if dialog_name != "Preferences":
          return

        # Make sure defaults are loaded before copying the initial configs
        dialog_instance.update_global()
        dialog_instance.update_profile()
        initial_meta = aqt.mw.pm.meta.copy()
        initial_profile_conf = aqt.mw.pm.profile.copy()

        def on_preferences_save() -> None:
          aqt.mw.pm.save = lambda: None

          details = make_config_differences_str(initial_meta, aqt.mw.pm.meta)
          details += make_config_differences_str(initial_profile_conf,
                                                 aqt.mw.pm.profile)
          if not details:
            return

          message_box = QMessageBox(
            QMessageBox.Icon.Warning,
            "NixOS Info",
            ("Anki settings are currently being managed by Home Manager.<br>"
             "Changes to certain settings won't be saved.")
          )
          message_box.setDetailedText(details)
          message_box.exec()

        aqt.mw.pm.save = on_preferences_save

      def state_will_change(new_state: aqt.main.MainWindowState,
                            old_state: aqt.main.MainWindowState):
        if new_state != "profileManager":
          return

        QMessageBox.warning(
          aqt.mw,
          "NixOS Info",
          ("Profiles cannot be changed or added while settings are managed with "
           "Home Manager.")
        )


      # Ensure Anki doesn't try to save to the read-only DB settings file.
      aqt.mw.pm.save = lambda: None

      # Tell the user when they try to change settings that won't be persisted.
      aqt.gui_hooks.dialog_manager_did_open_dialog.append(dialog_did_open)

      # Show warning when users try to switch or customize profiles.
      aqt.gui_hooks.state_will_change.append(state_will_change)
    '';
  };
}
