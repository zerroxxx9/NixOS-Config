rec {
  background = "#2b3e50";
  foreground = "#f8f8f2";

  normal = {
    black = "#19242f";
    red = "#e94b35";
    green = "#199c4b";
    yellow = "#f0cc04";
    blue = "#5c98cd";
    magenta = "#ca94ff";
    cyan = "#8be0fd";
    white = "#f8f8f2";
  };

  bright = {
    black = "#2f3943";
    red = "#ff6541";
    green = "#72cc5a";
    yellow = "#ffffa5";
    blue = "#d6acff";
    magenta = "#d4a9ff";
    cyan = "#b9ecfd";
    white = "#ffffff";
  };

  # Noctalia's 16 UI colour roles. Every value below is taken from the palette
  # above except onSurfaceVariant, which has no equivalent in a 16-colour
  # terminal scheme and is a desaturated foreground for secondary text.
  roles = {
    mPrimary = normal.blue;
    mOnPrimary = normal.black;
    mSecondary = normal.cyan;
    mOnSecondary = normal.black;
    mTertiary = normal.magenta;
    mOnTertiary = normal.black;
    mError = normal.red;
    mOnError = foreground;
    mSurface = normal.black;
    mOnSurface = foreground;
    mSurfaceVariant = background;
    mOnSurfaceVariant = "#c3cdd8";
    mOutline = bright.black;
    mShadow = normal.black;
    mHover = bright.black;
    mOnHover = foreground;
  };

  client = {
    bg0 = normal.black; # #19242f — primary background (chat, main view)
    bg1 = "#131b23"; # secondary (sidebars)
    bg2 = "#0d1319"; # tertiary (guild bar, shadows)
    bg3 = "#243544"; # cards, modals, inputs, active tabs
    bg4 = background; # #2b3e50 — modifier/hover/select

    text0 = foreground; # normal text
    text1 = bright.white; # brighter text
    text2 = roles.mOnSurfaceVariant; # dimmed/secondary text

    accent = normal.blue;
  };

  # Noctalia palette JSON `terminal` object.
  terminal = {
    inherit background foreground normal bright;
    cursor = foreground;
    cursorText = background;
    selectionBg = foreground;
    selectionFg = background;
  };
}
