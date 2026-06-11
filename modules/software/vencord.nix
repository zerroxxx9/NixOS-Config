{
  lib,
  pkgs,
  config,
  hostVariables,
  ...
}: let
  homeDir = "/home/${hostVariables.username}";
  matugenDiscordCss = "${homeDir}/.cache/matugen/discord.css";
  vesktopThemeDir = "${homeDir}/.config/vesktop/themes";
  liveThemeCss = "${vesktopThemeDir}/zerrox-live.css";
  liveThemeContent = ''
    @import url('./zerrox.css');
    @import url('file://${matugenDiscordCss}');

    :root {
      --background-image: url('file://${homeDir}/.cache/quickshell/wallpaper_picker/current_wallpaper.png') !important;
      --background-image-fallback: url('file://${homeDir}/.dotfiles/assets/wallpaper/5.jpg') !important;
    }
  '';
  wallpaper = name: "file://${homeDir}/.dotfiles/assets/wallpaper/${name}";
  discordVariant = {
    wallpaperName,
    base,
    mantle,
    crust,
    text,
    subtext0,
    subtext1,
    surface0,
    surface1,
    surface2,
    overlay0,
    overlay1,
    overlay2,
    crustRgb,
    textRgb,
    accent,
    accentAlt,
  }: ''
    @import url('./zerrox.css');

    :root {
      --background-image: url('${wallpaper wallpaperName}');
      --background-image-fallback: url('${wallpaper wallpaperName}');
      --base: ${base};
      --mantle: ${mantle};
      --crust: ${crust};
      --surface0: ${surface0};
      --surface1: ${surface1};
      --surface2: ${surface2};
      --overlay0: ${overlay0};
      --overlay1: ${overlay1};
      --overlay2: ${overlay2};
      --text-color: ${text};
      --subtext0: ${subtext0};
      --subtext1: ${subtext1};
      --background-solid: var(--base);
      --background-solid-dark: var(--mantle);
      --background-solid-darker: var(--crust);
      --background-overlay: rgba(${crustRgb}, 0.58);
      --background-overlay-strong: rgba(${crustRgb}, 0.78);
      --accent: ${accent};
      --accent-alt: ${accentAlt};
      --md-black: ${crustRgb};
      --dm-white: ${textRgb};
      --accentcolor: var(--accent);
      --vaccentcolor-hover: rgb(var(--accent));
      --vaccentcolor-active: rgb(var(--accent));
    }

    button {
      --accentcolor: var(--accent-alt);
    }
  '';
  colors = {
    base = "#1e1e2e";
    mantle = "#181825";
    crust = "#11111b";
    text = "#cdd6f4";
    subtext0 = "#a6adc8";
    subtext1 = "#bac2de";
    surface0 = "#313244";
    surface1 = "#45475a";
    surface2 = "#585b70";
    overlay0 = "#6c7086";
    overlay1 = "#7f849c";
    overlay2 = "#9399b2";

    rgb = {
      crust = "17, 17, 27";
      text = "205, 214, 244";
      blue = "137, 180, 250";
      sapphire = "116, 199, 236";
    };
  };
in {
  options.modules.software.vencord = {
    enable = lib.mkEnableOption "Vesktop with a customized Vencord setup";
  };

  config = lib.mkIf config.modules.software.vencord.enable {
    home-manager.users.${hostVariables.username} = {
      programs.vesktop = {
        enable = true;
        package = pkgs.unstable.vesktop;
        vencord.useSystem = true;

        settings = {
          appBadge = true;
          arRPC = true;
          checkUpdates = false;
          customTitleBar = false;
          disableMinSize = true;
          discordBranch = "stable";
          hardwareAcceleration = true;
          minimizeToTray = true;
          splashBackground = colors.base;
          splashColor = colors.text;
          splashTheming = true;
          staticTitle = true;
          tray = true;
        };

        vencord = {
          themes.zerrox = ''
            @import url('https://fonts.googleapis.com/css2?family=Karla:wght@400;500;600;700&display=swap');
@import url('https://mwittrien.github.io/BetterDiscordAddons/Themes/BlurpleRecolor/BlurpleRecolor.css');
@import url('https://discord-custom-covers.github.io/usrbg/dist/usrbg.css');
@import url('file://${matugenDiscordCss}');

button {
	--accentcolor: var(--accent-alt);
}


/* Root Variables */

:root {
	--font-primary: 'Karla', sans-serif;
	--font-display: var(--font-primary) !important;
	/* Dark Matter Variables */
	--avatar-size: 32px;
	--background-image: url('file://${homeDir}/.cache/quickshell/wallpaper_picker/current_wallpaper.png');
	--background-image-fallback: url('file://${homeDir}/.dotfiles/assets/wallpaper/5.jpg');
	--home-image: url('https://i.imgur.com/233d55Y.gif');
	--base: ${colors.base};
	--mantle: ${colors.mantle};
	--crust: ${colors.crust};
	--surface0: ${colors.surface0};
	--surface1: ${colors.surface1};
	--surface2: ${colors.surface2};
	--overlay0: ${colors.overlay0};
	--overlay1: ${colors.overlay1};
	--overlay2: ${colors.overlay2};
	--text-color: ${colors.text};
	--subtext0: ${colors.subtext0};
	--subtext1: ${colors.subtext1};
	--background-solid: var(--base);
	--background-solid-dark: var(--mantle);
	--background-solid-darker: var(--crust);
	--background-overlay: rgba(${colors.rgb.crust}, 0.58);
	--background-overlay-strong: rgba(${colors.rgb.crust}, 0.78);
	--accent: ${colors.rgb.blue};
	--accent-alt: ${colors.rgb.sapphire};
	--md-black: ${colors.rgb.crust};
	--dm-white: ${colors.rgb.text};
	/* BlurpleRecolor */
	--accentcolor: var(--accent);
	--vaccentcolor-hover: rgb(var(--accent));
	--vaccentcolor-active: rgb(var(--accent));
}

:not(div[class*="userProfile"][class*="unThemed"]).theme-dark,
:not(div[class*="userProfile"]).theme-light,
div[class*="userProfile"][class*="unThemed"].theme-light {
	/* Discord vars */
	--background-primary: rgba(var(--md-black), 0.55);
	--background-mobile-primary: var(--background-primary);
	--background-secondary: rgba(var(--md-black), 0.45);
	--background-mobile-secondary: var(--background-secondary);
	--background-secondary-alt: rgba(var(--md-black), 0.75);
	--background-tertiary: rgba(var(--md-black), 0.35);
	--background-floating: rgba(var(--md-black), 0.82);
	--background-secondary: rgba(var(--md-black), 0.45);
	--background-accent: rgba(var(--md-black), 0.65);
	--background-message-hover: rgba(var(--md-black), 0.4);
	--bg-base-primary: rgba(var(--md-black), 0.55);
	--bg-base-secondary: rgba(var(--md-black), 0.45);
	--bg-base-tertiary: rgba(var(--md-black), 0.35);
	--background-base-lowest: transparent;
	--background-base-lower: rgba(var(--md-black), 0.35);
	--background-base-low: rgba(var(--md-black), 0.45);
	--background-base-subtle: rgba(var(--md-black), 0.55);
	--background-surface-high: rgba(var(--md-black), 0.65);
	--background-surface-higher: rgba(var(--md-black), 0.72);
	--background-surface-highest: rgba(var(--md-black), 0.82);
	--app-background-frame: transparent;
	--app-border-frame: transparent;
	--chat-background-default: transparent;
	--home-background: transparent;
	--channeltextarea-background: transparent;
	--activity-card-background: rgba(var(--dm-white), 0.05);
	--deprecated-store-bg: transparent;
	--background-modifier-hover: rgba(var(--md-black), 0.3);
	--background-modifier-active: rgba(var(--md-black), 0.3);
	--background-modifier-selected: rgba(var(--md-black), 0.6);
	--elevation-low: inset 0 -1px 0 0 rgba(var(--md-black), 0.3);
	--channels-default: rgba(var(--dm-white), 0.3);
	--deprecated-quickswitcher-input-background: var(--background-solid);
	--header-primary: rgba(var(--dm-white), 1);
	--header-secondary: rgba(var(--dm-white), 0.6);
	--text-normal: rgba(var(--dm-white), 0.6);
	--text-muted: var(--subtext0);
	--interactive-muted: rgba(var(--dm-white), 0.15);
	--interactive-normal: rgba(var(--dm-white), 0.5);
	--interactive-hover: rgba(var(--dm-white), 0.75);
	--interactive-active: rgba(var(--dm-white), 1);
	--deprecated-card-bg: rgba(var(--dm-white), 0.05);
	--text-link: rgba(var(--accent), 1);
	--focus-primary: rgba(var(--accent), 1);
    --modal-background: var(--background-solid);
    --modal-footer-background: var(--background-solid-darker);
}

::selection {
	background-color: rgba(var(--accent-alt), 0.5);
}


/* Scrollbars */

::-webkit-scrollbar {
	width: 14px !important;
}

 ::-webkit-scrollbar-thumb {
	border-radius: 8px !important;
	border: 3px solid transparent !important;
	background-color: rgba(var(--accent-alt), 1) !important;
}

 ::-webkit-scrollbar-track {
	visibility: visible !important;
	border-radius: 8px !important;
	border: 3px solid transparent !important;
	background-color: rgba(0, 0, 0, 0.3) !important;
	background-clip: padding-box !important;
}

.none-2Eo-qx::-webkit-scrollbar {
	display: none !important;
}


/* Titlebar */

div[class*="typeWindows-"] {
	--background-modifier-hover: rgba(var(--dm-white), 0.05);
	--background-modifier-active: rgba(var(--dm-white), 0.075);
	height: 26px;
}

div[class*="typeWindows-"]>div:first-child {
	display: none;
}

div[class*="typeWindows-"]>div[role="button"] {
	height: 30px;
	width: 36px;
}

div[class*="typeWindows-"]::after {
	content: none;
}


/* Guilds */

nav[class*="guilds-"] {
    background: transparent;
}
ul[data-list-id='guildsnav'] {
	--background-secondary: var(--background-solid);
    	--background-primary: rgba(var(--dm-white), 0.1);
	margin-bottom: 70px;
	background-color: rgba(var(--md-black), 0.6);
	border-right: 1px solid rgba(var(--md-black), 0.2);
	box-shadow: inset -10px 0px 20px -10px rgba(var(--md-black), 0.3);
}

ul[data-list-id='guildsnav'] ::-webkit-scrollbar {
	display: none;
}

ul[data-list-id='guildsnav']>div[dir] {
	padding-top: 18px;
}

ul[data-list-id='guildsnav'] [class^="pill-"],
ul[data-list-id='guildsnav'] [class^="pill-"]>div {
	height: 40px !important;
}

ul[data-list-id='guildsnav'] div[style*="height: 56"],
ul[id^="folder-items-"] {
	height: auto !important;
}

ul[data-list-id='guildsnav'] [class^="pill-"] span {
	width: 10px;
	margin-left: -5px;
	border-radius: 20px;
}

[data-list-id='guildsnav'] [class^="pill-"] span[style^="opacity: 1; height: 40"] {
	--header-primary: rgba(var(--accent), 1);
}

span[class^="expandedFolderBackground-"] {
	--background-secondary: rgba(var(--md-black), 0.25);
	border-radius: 14px;
	width: 40px;
	left: 16px;
}

.wrapper-28eC3z,
[data-list-id='guildsnav'] [data-dnd-name] > div,
[data-list-id='guildsnav'] svg[width="48"] {
	width: 40px;
	height: 40px;
}

div[data-list-item-id="guildsnav___home"] {
	background: var(--home-image) top center/110% no-repeat;
}

div[class^="unreadMentionsIndicatorBottom-"] {
	bottom: 70px;
}

#app-mount [data-list-item-id="guildsnav___home"]>div {
	color: transparent;
	background-color: transparent;
}

div[data-list-item-id="guildsnav___create-join-button"],
div[data-list-item-id="guildsnav___guild-discover-button"] {
	transition: 150ms ease;
	opacity: 0.5;
	background-color: var(--background-solid) !important;
	color: rgba(var(--dm-white), 0.3) !important;
	border: 1px dashed rgba(var(--dm-white), 0.3);
	border-radius: 50px;
}

div[data-list-item-id="guildsnav___create-join-button"]:hover,
div[data-list-item-id="guildsnav___guild-discover-button"]:hover {
	opacity: 1;
}


/* Sidebar */

.platform-win [class^="sidebar-"] {
	border-radius: 0;
    background-color: transparent;
}

div[class^="sidebar-"] nav,
#private-channels {
	background: var(--background-secondary) !important;
	--background-tertiary: rgba(var(--md-black), 0.35);
}

div[class^="sidebar-"]>nav>div[class^="searchBar"] {
	height: 54px;
}

/* members wrapper */
.container-2o3qEW {
	--background-secondary: rgba(var(--md-black), 0.4);
	--background-modifier-hover: rgba(var(--dm-white), 0.07);
	--background-modifier-active: var(--background-modifier-hover);
	--background-modifier-selected: rgba(var(--dm-white), 0.07);
    background: rgba(var(--md-black), 0.9);
}

div[data-list-id^="members-"][class*="scrollerBase-"] {
    background: transparent;
}

div[data-list-id^="members-"] [class*="placeholder"] {
	--backgorund-primary: var(--text-normal);
}

div[class^='nowPlayingColumn'] {
	--background-secondary: transparent;
	--background-primary: rgba(var(--md-black), 0.5);
	--background-modifier-hover: rgba(var(--dm-white), 0.075);
}
div[class^="members-"] div[class^="member-"] {
    background-color: transparent;
}

#channels div[class^="unread-"] {
	--interactive-active: rgba(var(--accent), 1);
}


/* Sidebar Header */

nav[aria-label]>div>header {
	display: flex;
	flex-direction: column;
	justify-content: center;
	height: 54px;
	--background-accent: rgba(var(--accent), 1);
	--background-modifier-hover: rgba(var(--md-black), 0.25);
}


/* Outer containers */

html,
body,
#app-mount {
	background: transparent !important;
}

#app-mount {
    background-color: transparent !important;
	--background-tertiary: transparent;
	--background-secondary: transparent;
	position: relative;
	isolation: isolate;
}

#app-mount::before {
	content: "";
	position: fixed;
	inset: 0;
	background-image: var(--background-image), var(--background-image-fallback);
	background-position: center;
	background-size: cover;
	background-repeat: no-repeat;
	z-index: 0;
	pointer-events: none;
}

#app-mount::after {
	content: "";
	position: fixed;
	inset: 0;
	background: var(--background-overlay);
	z-index: 0;
	pointer-events: none;
}

#app-mount>* {
	position: relative;
	z-index: 1;
}

#app-mount>div[class^="appDevToolsWrapper-"] {
	--background-primary: transparent;
	--background-tertiary: transparent;
	--background-secondary: rgba(var(--md-black), 0.7);
	background-color: rgba(var(--md-black), 0.4);
}
div[class^="notAppAsidePanel"]>div[class^="app"]>div[class^="app"],
div[class*="notAppAsidePanel"]>div[class*="app"]>div[class*="app"],
div[class^="app"]>div[class^="bg"],
div[class*="app"]>div[class*="bg"],
#app-mount [class^="bg"],
#app-mount [class*=" bg"],
#app-mount [class^="base"],
#app-mount [class*=" base"],
#app-mount [class^="app_"],
#app-mount [class*=" app_"],
#app-mount [class^="app-"],
#app-mount [class*=" app-"] {
    background: transparent !important;
    background-color: transparent !important;
}

#app-mount [class*="layers"],
#app-mount [class*="layer"],
#app-mount [class*="base"],
#app-mount [class*="chat"],
#app-mount [class*="chatContent"],
#app-mount [class*="content"],
#app-mount [class*="sidebar"],
#app-mount [class*="guilds"],
#app-mount [class*="members"],
#app-mount [class*="privateChannels"],
#app-mount [class*="pageWrapper"],
#app-mount [class*="standardSidebarView"],
#app-mount [class*="contentRegion"],
#app-mount [class*="sidebarRegion"],
#app-mount [class*="scroller"] {
	background-color: transparent !important;
}

div[class*="baseLayer"]>div[class*="container"] {
    background-color: var(--background-overlay);
}

nav+div [class*='sidebar'],
nav+div[class*='base'] {
	overflow: visible !important;
	position: relative;
	max-width: calc(100% - 72px);
}

nav+div[class*='base'] > div[class*="notice"] {
	border-radius: 0;
}

div[class*='base']>div,
section[class*="themed-"] {
	--background-secondary: rgba(var(--md-black), 0.7);
	--background-tertiary: rgba(var(--dm-white), 0.05);
	--background-primary: rgba(var(--md-black), 0.8);
}

#app-mount>div:not([class^="appDevToolsWrapper-"]),
.autocomplete-1vrmpx {
	--background-primary: rgba(var(--md-black), 0.55);
	--background-secondary: rgba(var(--md-black), 0.45);
	--background-secondary-alt: rgba(var(--md-black), 0.75);
	--background-tertiary: rgba(var(--md-black), 0.35);
	--background-floating: rgba(var(--md-black), 0.82);
	--bg-base-primary: rgba(var(--md-black), 0.55);
	--bg-base-secondary: rgba(var(--md-black), 0.45);
	--bg-base-tertiary: rgba(var(--md-black), 0.35);
	--background-base-lowest: transparent;
	--background-base-lower: rgba(var(--md-black), 0.35);
	--background-base-low: rgba(var(--md-black), 0.45);
	--background-base-subtle: rgba(var(--md-black), 0.55);
	--background-surface-high: rgba(var(--md-black), 0.65);
	--background-surface-higher: rgba(var(--md-black), 0.72);
	--background-surface-highest: rgba(var(--md-black), 0.82);
	--app-background-frame: transparent;
	--app-border-frame: transparent;
	--chat-background-default: transparent;
	--home-background: transparent;
}

#app-mount>div:not([class^="appDevToolsWrapper-"]) {
	background: transparent !important;
}


/* Header */

#app-mount section[class*="themed"],
#app-mount [class*="container"][class*="themed"],
#app-mount [class*="container__"][class*="themed__"],
#app-mount [class*="title"][class*="container"],
#app-mount [class*="subtitleContainer"],
#app-mount [class*="subtitleContainer"] section,
#app-mount [class*="subtitleContainer"]>[class*="container"] {
	height: 54px;
	box-shadow: none !important;
	background: transparent !important;
	background-color: transparent !important;
	background-image: none !important;
	border-bottom-color: transparent !important;
	--background-primary: transparent;
	--background-secondary: transparent;
	--background-tertiary: transparent;
	--bg-base-primary: transparent;
	--bg-base-secondary: transparent;
	--bg-base-tertiary: transparent;
	--background-base-lowest: transparent;
	--background-base-lower: transparent;
	--background-base-low: transparent;
	--background-base-subtle: transparent;
}

section>div>a[href*="support.discord.com"] {
	display: none;
}

#app-mount section[class*="themed"]::before,
#app-mount section[class*="themed"]::after,
#app-mount section[class*="themed"] ::before,
#app-mount section[class*="themed"] ::after,
#app-mount [class*="container"][class*="themed"]::before,
#app-mount [class*="container"][class*="themed"]::after,
#app-mount [class*="children"]::after,
#app-mount [class*="toolbar"]::before,
#app-mount [class*="toolbar"]::after {
	content: none;
	display: none !important;
	background: none !important;
	background-image: none !important;
}

section div[class^="toolbar"]>div[role] {
	margin: 0 4px;
	transition: 150ms ease;
	display: flex;
	align-items: center;
	justify-content: center;
	border-radius: 3px;
	width: 28px;
	height: 28px;
}

section div[class^="toolbar"]>div[role] svg {
	width: 22px;
}

section div[class^="toolbar"]>div[role][class*="selected-"] {
	background-color: rgba(var(--dm-white), 0.1);
}


/* Panels */

div[class^='sidebar-']>section {
	--background-primary: rgba(var(--dm-white), 0.07);
	--background-secondary: rgba(var(--dm-white), 0.1);
	--background-secondary-alt: rgba(var(--md-black), 0.95);
	margin-bottom: 70px;
}

div[class^='sidebar-']>section>div:last-child {
	background-color: var(--background-secondary-alt);
	box-sizing: border-box;
	height: 70px;
	padding: 0 18px;
	width: calc(100% + 72px);
	position: absolute;
	left: -72px;
	bottom: 0;
}
div[class^="sidebar-"]>section>div:last-child [class^="avatarWrapper-"] {
    flex: 1;
}


/* Content */

div[class^='chat'] {
	--background-floating: rgba(var(--md-black), 0.5);
    background: transparent;
}

div[class^="container-"][id^="chat-messages-"] {
	--background-modifier-hover: var(--background-solid-dark);
}

div[class^='chat'] main form {
	margin-top: 0;
}

div[class^='chat'] main form::before {
	content: none;
}

div[data-list-id="chat-messages"] {
	--background-primary: transparent;
	--background-secondary: rgba(var(--dm-white), 0.05);
	--background-accent: rgba(var(--dm-white), 0.1);
}

div[class^="channelTextArea-"] {
	--background-secondary: transparent;
	box-shadow: inset 0 0 0 2px rgba(var(--dm-white), 0.1);
	transition: 250ms ease;
	margin-bottom: 24px;
	margin-top: 12px;
	border-radius: 5px;
}

div[id^="chat-messages-"]+div:not([id]):last-child {
	height: 8px;
}

div[id^="chat-messages-"][class*="cozy-"] {
	padding-left: calc(var(--avatar-size) * 2);
}

div[id^="chat-messages-"] {
	margin-left: 8px;
	margin-right: 8px;
	border-radius: 4px;
}

div[id^="chat-messages-"]>div[class^="buttonContainer-"] {
	transform: scale(.85);
	top: 1px;
}

div[id^="chat-messages-"] {
	--background-primary: rgba(var(--md-black), 0.5);
}

div[id^="chat-messages-"]>div>[class^="avatar-"] {
	margin-top: 6px;
	width: var(--avatar-size);
	height: var(--avatar-size);
}

div[id^="chat-messages-"][class*="cozy-"] div::before {
	--gutter: 13px;
}

.mention {
	transition: 150ms ease;
	color: rgba(var(--accent), 1) !important;
	background-color: rgba(var(--accent), 0.3);
	padding: 3px 5px;
	border-radius: 5px;
}

.mention:hover {
	background-color: rgba(var(--accent), 0.3) !important;
}

#app-mount .container-2cd8Mz {
	background: var(--background-primary);
}

div[class*="barBase-"] {
	padding-bottom: 0;
	background-color: rgba(var(--accent-alt), 0.9);
}


/* Codeblocks */

html pre {
	border-radius: 0;
	background: transparent;
	border-color: rgba(255, 255, 255, 0.1);
}

pre code.hljs {
	border: none;
	background-color: rgba(var(--dm-white), 0.1);
	color: rgba(var(--dm-white), 0.7);
	padding: 1em;
}

html code.inline,
html code.inline {
	background: rgba(var(--dm-white), 0.1);
	color: rgba(var(--dm-white), 0.7);
	padding: 0.3em 0.6em;
	border-radius: 3px;
}


/* Settings */

div[aria-label*="_SETTINGS"],
div[aria-label*="_DEBUG"] {
	--background-primary: transparent;
	--background-secondary: rgba(var(--md-black), 0.7);
}

div[class^="sidebarRegionScroller-"]>nav {
	--background-secondary: transparent;
}

div[class^="contentRegion-"] {
	--background-primary: rgba(var(--md-black), 0.8);
}

div[class^="contentRegion-"] div[style^="overflow: hidden scroll"] {
	background-color: transparent;
	--background-primary: rgba(var(--md-black), 0.1);
	--background-secondary: rgba(var(--md-black), 0.2);
	--background-secondary-alt: rgba(var(--md-black), 0.25);
	--background-tertiary: rgba(var(--dm-white), 0.1);
}

div[aria-label*="_SETTINGS"] aside>div {
	--background-primary: transparent;
}

div[aria-label*="_SETTINGS"] aside>div::-webkit-scrollbar-track {
	visibility: hidden !important;
}

.bd-addon-list {
	--background-secondary: var(--background-solid);
	--background-secondary-alt: var(--background-solid-dark);
}


/* Tab Bar */

div[class*="topPill"],
nav>div[role="tablist"],
.bd-tab-bar {
	--background-accent: rgba(var(--accent));
	--background-modifier-hover: rgba(var(--dm-white), 0.05);
	--background-modifier-active: rgba(var(--dm-white), 0.075);
	--background-modifier-selected: rgba(var(--accent), 0.25);
}


/* Server Discovery */

div[class^="sidebar"]+[class^="pageWrapper"] {
	--background-secondary: rgba(var(--md-black), 0.8);
	background-color: var(--background-secondary);
}


/* Crash Page */

div[class*="errorPage"] {
	--background-secondary: rgba(var(--md-black), 0.7) !important;
}


/* Tooltips */

div[class^="tooltip-"] {
	--background-floating: rgba(var(--accent-alt), 1);
	--text-normal: #e0e0e0;
}


/* Buttons */

button[class*="button-"][class*="color"],
.bd-button {
	--vaccentcolor: var(--accent-alt);
}

.bd-button {
	--bd-blue: rgba(var(--accent-alt), 1);
}


/* Context Menu */

div[role="menuitem"] {
	--vaccentcolor: var(--accent-alt);
}

div[role="menuitem"]:active {
	--vaccentcolor: var(--accent);
}


/* Depreceated Components */


/* These use hardcoded colors, no need to bother with strange selectors */

#app-mount .footer-2gL1pp,
#app-mount .footer-3mqk7D {
	background-color: var(--background-secondary);
	box-shadow: none;
}

#app-mount .root-1gCeng,
#app-mount .addGamePopout-2RY8Ju,
#app-mount .keyboardShortcutsModal-3piNz7,
#app-mount .emojiAliasInput-1y-NBz .emojiInput-1aLNse,
.perksModal-fSYqOq .perk-2WeBWW,
#app-mount .uploadModal-2ifh8j,
#app-mount .contentWrapper-3WC1ID,
#app-mount .contentWarningPopout-n5JsIs {
	background-color: var(--background-primary);
}

#app-mount .codeRedemptionRedirect-1wVR4b,
#app-mount .userSettingsVoice-iwdUCU .previewOverlay-2O7_KC,
#app-mount .inset-3sAvek {
	background-color: var(--background-tertiary);
	border: none;
}

#app-mount .paymentPane-3bwJ6A,
#app-mount .tierBody-x9kBBp,
#app-mount .tierBody-16Chc9,
#app-mount .barBackground-2EEiLw,
#app-mount .body-3iLsc4,
#app-mount .footer-1fjuF6,
#app-mount .container-3ayLPN,
#app-mount .colorPickerCustom-2CWBn2,
#app-mount .tierMarkerBackground-3q29am,
.css-3vaxre-menu,
.css-dwar6a-menu,
#app-mount .autocomplete-1vrmpx,
.categoryHeader-O1zU94,
#app-mount .popoutList-T9CKZQ,
#app-mount .quickSelectPopout-X1hvgV,
.colorable-1bkp8v.primaryDark-3mSFDl,
.tile-2naSqK,
.videoWrapper-2v09vt,
#app-mount .spoilerText-3p6IlD.hidden-HHr2R9 {
	background-color: var(--background-solid);
}

#app-mount .expandedInfo-3kfShd,
#app-mount .tierHeaderLocked-1a2opw,
#app-mount .tierHeaderLocked-1s2JJz,
#app-mount .headerNormal-T_seeN,
#app-mount .focused-2bY0OD,
.colorable-1bkp8v.primaryDark-3mSFDl:hover {
	background-color: var(--background-solid-dark);
}

#app-mount .payment-xT17Mq {
	background-color: transparent;
	border-bottom-color: rgba(var(--dm-white), 0.025);
}

#app-mount .bottomDivider-1K9Gao,
#app-mount .focused-2bY0OD {
	border-bottom-color: var(--background-solid-dark);
}

#app-mount div[data-list-id="billing-history"],
#app-mount div[data-list-id^="private-channels-"],
#app-mount .media-engine-video,
.react-datepicker,
.react-datepicker__header,
.react-datepicker__day--outside-month,
.react-datepicker__day--disabled,
div[data-list-id^="members-"],
div[data-list-id^="members-"]>div {
	background-color: transparent !important;
}

.react-datepicker__day--disabled {
	opacity: .6;
}

#app-mount .react-datepicker__day {
	border-top-color: var(--background-secondary);
	border-left-color: var(--background-secondary);
}

#app-mount .background-3xPPFc,
#app-mount .tierInProgress-3mBoXq {
	color: var(--background-solid);
}

.option-96V44q:after {
	content: none;
}

#app-mount .option-96V44q.selected-rZcOL-,
#app-mount .selected-1Tbx07,
#app-mount .quickSelectPopoutOption-opKBx9:hover,
#app-mount .outer-1AjyKL.active-1xchHY,
#app-mount .outer-1AjyKL.interactive-3B9GmY:hover {
	background-color: var(--background-modifier-hover);
}

.css-3vaxre-menu,
.tierMarker-5HkGJ_[style] {
	border-color: rgba(var(--dm-white), 0.025) !important;
}

#app-mount .searchAnswer-3Dz2-q,
#app-mount .searchFilter-2ESiM3,
#app-mount .option-1B5ZV8,
#app-mount .pill-2pQByF {
	background-color: rgba(var(--accent-alt), 1);
	color: #fff;
}

#app-mount .keybindShortcut-1BD6Z1 span {
	background: var(--background-solid-dark);
	box-shadow: inset 0 -4px 0 var(--background-solid-darker);
}

#app-mount .perksModal-fSYqOq {
	background: rgba(var(--md-black), 0.7);
}

#app-mount .card-FDVird:before {
	background: var(--background-modifier-hover);
	border: none;
}


/* Login Page */

div[class^="splashBackground"] canvas,
div[class^="splashBackground"] img {
	display: none;
}

/* Modals */

div[class*="footerSeparator"] {
	box-shadow: none !important;
}

/* Forums */
.container-3wLKDe {
    background: var(--background-primary);
}
li[class^="card-"]>div[class^="container-"] {
    background: var(--background-floating);
}
          '';

          themes."zerrox-orbit" = discordVariant {
            wallpaperName = "planets.jpg";
            base = "#05090a";
            mantle = "#0b1210";
            crust = "#020405";
            text = "#e2ece8";
            subtext0 = "#aebdb5";
            subtext1 = "#c6d2ca";
            surface0 = "#13201b";
            surface1 = "#1e3128";
            surface2 = "#2f4738";
            overlay0 = "#506657";
            overlay1 = "#758875";
            overlay2 = "#aebdb5";
            crustRgb = "2, 4, 5";
            textRgb = "226, 236, 232";
            accent = "92, 154, 110";
            accentAlt = "215, 171, 72";
          };

          themes."zerrox-moon" = discordVariant {
            wallpaperName = "moon.jpg";
            base = "#060913";
            mantle = "#0d1428";
            crust = "#03050b";
            text = "#e7ecff";
            subtext0 = "#aeb8d0";
            subtext1 = "#c8d2eb";
            surface0 = "#17213d";
            surface1 = "#22305a";
            surface2 = "#334578";
            overlay0 = "#4f6091";
            overlay1 = "#7886ad";
            overlay2 = "#aeb8d0";
            crustRgb = "3, 5, 11";
            textRgb = "231, 236, 255";
            accent = "74, 120, 255";
            accentAlt = "185, 197, 218";
          };

          themes."zerrox-fuji" = discordVariant {
            wallpaperName = "fuji.jpg";
            base = "#101817";
            mantle = "#162321";
            crust = "#0a0f0e";
            text = "#e4eee8";
            subtext0 = "#b9c8c0";
            subtext1 = "#d1ddd6";
            surface0 = "#22312f";
            surface1 = "#314542";
            surface2 = "#49625d";
            overlay0 = "#617c75";
            overlay1 = "#8aa39a";
            overlay2 = "#b9c8c0";
            crustRgb = "10, 15, 14";
            textRgb = "228, 238, 232";
            accent = "121, 190, 175";
            accentAlt = "238, 168, 126";
          };

          themes."zerrox-waves" = discordVariant {
            wallpaperName = "waves.jpg";
            base = "#120b2a";
            mantle = "#1b103d";
            crust = "#080513";
            text = "#f0e9ff";
            subtext0 = "#c5b7df";
            subtext1 = "#ded1f6";
            surface0 = "#28185a";
            surface1 = "#3a2278";
            surface2 = "#4f2fa0";
            overlay0 = "#704fc0";
            overlay1 = "#9b7ee0";
            overlay2 = "#c5b7df";
            crustRgb = "8, 5, 19";
            textRgb = "240, 233, 255";
            accent = "184, 77, 245";
            accentAlt = "42, 205, 226";
          };

          themes."zerrox-blackdots" = discordVariant {
            wallpaperName = "blackdots.jpg";
            base = "#090909";
            mantle = "#111111";
            crust = "#030303";
            text = "#e8e8e8";
            subtext0 = "#b8b8b8";
            subtext1 = "#d0d0d0";
            surface0 = "#191919";
            surface1 = "#252525";
            surface2 = "#343434";
            overlay0 = "#555555";
            overlay1 = "#808080";
            overlay2 = "#b8b8b8";
            crustRgb = "3, 3, 3";
            textRgb = "232, 232, 232";
            accent = "168, 168, 168";
            accentAlt = "96, 96, 96";
          };

          settings = {
            autoUpdate = false;
            autoUpdateNotification = false;
            disableMinSize = true;
            enabledThemes = ["zerrox-live.css"];
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

      home.activation.ensureVesktopLiveTheme = ''
        mkdir -p "${vesktopThemeDir}"
        cat > "${liveThemeCss}" <<'EOF'
${liveThemeContent}
EOF
      '';
    };
  };
}
