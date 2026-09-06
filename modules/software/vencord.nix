# Vesktop, themed by Noctalia.
#
# Noctalia's community `discord` template renders its Discord stylesheets from
# the wallpaper palette straight into ~/.config/vesktop/themes/ on every colour
# change (enabled in modules/gui/noctalia.nix). Home Manager owns the Vencord
# settings file, so the enabled theme is selected here rather than in
# Vesktop's UI.
{
  lib,
  pkgs,
  config,
  hostVariables,
  ...
}: let
  cfg = config.modules.software.vencord;

  palette = import ../gui/palette.nix;
  inherit (palette) client;

  # Filenames are fixed by the community template's template.toml.
  themeFile =
    {
      midnight = "noctalia.theme.css";
      material = "noctalia-material.theme.css";
      system24 = "discord-system24.css";
    }
    .${
      cfg.theme
    };
in {
  options.modules.software.vencord = {
    enable = lib.mkEnableOption "Vesktop, themed by Noctalia, with a Vencord plugin set";

    theme = lib.mkOption {
      type = lib.types.enum ["midnight" "material" "system24"];
      default = "midnight";
      description = "Which of Noctalia's Discord stylesheets Vencord enables.";
    };
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
