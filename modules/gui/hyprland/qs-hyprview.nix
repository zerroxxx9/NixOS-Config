{
  lib,
  pkgs,
  config,
  hostVariables,
  inputs,
  ...
}: let
  cfg = config.modules.gui.hyprland;
  quickshell = pkgs.quickshell or pkgs.unstable.quickshell;
  qt5compat = pkgs.qt6.qt5compat or pkgs.qt6Packages.qt5compat;
  qtQmlPath = lib.makeSearchPath "lib/qt-6/qml" [
    qt5compat
  ];
  qtPluginPath = lib.makeSearchPath "lib/qt-6/plugins" [
    qt5compat
  ];
  qsHyprviewQuickshell = pkgs.writeShellScriptBin "qs-hyprview-quickshell" ''
    export QML2_IMPORT_PATH="${qtQmlPath}:''${QML2_IMPORT_PATH:-}"
    export QT_PLUGIN_PATH="${qtPluginPath}:''${QT_PLUGIN_PATH:-}"
    exec ${lib.getExe quickshell} "$@"
  '';
  qsHyprview = inputs.qs-hyprview;
  qsHyprviewToggle = pkgs.writeShellScript "qs-hyprview-toggle" ''
    if ! ${lib.getExe qsHyprviewQuickshell} ipc -p ${qsHyprview} call expose toggle smartgrid; then
      ${lib.getExe qsHyprviewQuickshell} -p ${qsHyprview} >/tmp/qs-hyprview.log 2>&1 &
      sleep 0.5
      ${lib.getExe qsHyprviewQuickshell} ipc -p ${qsHyprview} call expose toggle smartgrid
    fi
  '';
in {
  config = lib.mkIf cfg.enable {
    home-manager.users.${hostVariables.username} = {
      home.packages = [
        quickshell
        qsHyprviewQuickshell
      ];

      wayland.windowManager.hyprland = {
        settings = {
          exec-once = [
            "${lib.getExe qsHyprviewQuickshell} -p ${qsHyprview}"
          ];

          decoration.dim_around = 0.8;

          layerrule = [
            "dim_around true, match:namespace quickshell:expose"
            "blur true, match:namespace quickshell:expose"
          ];

          bind = [
            "SUPER, TAB, exec, ${qsHyprviewToggle}"
          ];
        };
      };
    };
  };
}
