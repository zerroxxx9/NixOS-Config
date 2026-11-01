# Vesktop, themed by set-wallpaper (matugen).
#
# set-wallpaper renders the Discord stylesheet from the wallpaper palette into
# ~/.config/vesktop/themes/ on every change (modules/gui/matugen.nix). Home
# Manager owns the Vencord settings file, so the enabled theme is selected here
# rather than in Vesktop's UI.
{
  lib,
  pkgs,
  config,
  hostVariables,
  ...
}: let
  cfg = config.modules.software.vesktop;

  palette = import ../gui/palette.nix;
  inherit (palette) client;

  themeFile = "matugen.theme.css";
in {
  options.modules.software.vesktop = {
    enable = lib.mkEnableOption "Vesktop, themed from the wallpaper, with a Vencord plugin set";

  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${hostVariables.username} = {
      programs.vesktop = {
        enable = true;
        package = pkgs.unstable.vesktop;

        settings = {
          appBadge = true;
          arRPC = true;
          checkUpdates = false;
          customTitleBar = false;
          disableMinSize = true;
          discordBranch = "stable";
          hardwareAcceleration = true;
          minimizeToTray = true;
          # The splash window paints before any theme loads, so it keeps the
          # static palette rather than the wallpaper colours.
          splashBackground = client.bg2;
          splashColor = client.text0;
          splashTheming = true;
          staticTitle = true;
          tray = true;
        };

        vencord = {
          settings = {
            autoUpdate = false;
            autoUpdateNotification = false;
            disableMinSize = true;
            enabledThemes = [themeFile];
            notifyAboutUpdates = false;
            useQuickCss = false;

            plugins = {
              BetterFolders = {
                enabled = true;
                closeAllFolders = true;
                closeAllHomeButton = true;
                closeOthers = true;
                forceOpen = false;
                sidebar = true;
                sidebarAnim = true;
              };
              BetterRoleDot.enabled = true;
              CallTimer.enabled = true;
              ClearURLs.enabled = true;
              CopyFileContents.enabled = true;
              CopyUserURLs.enabled = true;
              CtrlEnterSend.enabled = true;
              FixImagesQuality.enabled = true;
              FixSpotifyEmbeds.enabled = true;
              FixYoutubeEmbeds.enabled = true;
              FriendsSince.enabled = true;
              ImageZoom = {
                enabled = true;
                nearestNeighbour = false;
                saveZoomValues = true;
                size = 100;
                zoom = 2;
              };
              # Plugins below render extra UI that the Discord themes style.
              MemberCount = {
                enabled = true;
                memberList = true;
                toolTip = true;
              };
              MessageClickActions = {
                enabled = true;
                enableDeleteOnClick = true;
                enableDoubleClickToEdit = true;
                enableDoubleClickToReply = true;
                requireModifier = true;
              };
              MutualGroupDMs.enabled = true;
              NoMaskedUrlPaste.enabled = true;
              NoOnboardingDelay.enabled = true;
              NoReplyMention.enabled = true;
              PinDMs.enabled = true;
              PlatformIndicators.enabled = true;
              QuickReply.enabled = true;
              ServerInfo.enabled = true;
              ShowConnections.enabled = true;
              SpotifyControls.enabled = true;
              TypingIndicator.enabled = true;
              VoiceChatDoubleClick.enabled = true;
              WebScreenShareFixes.enabled = true;
              WhoReacted.enabled = true;
            };
          };
        };
      };
    };
  };
}
