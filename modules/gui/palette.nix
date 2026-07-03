{lib, ...}: {
  options.modules.gui.palette = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    readOnly = true;
    default = {
      black = "#14171b";
      bg1 = "#1b1f26";
      bg2 = "#2c3138";
      surface = "#3d434c";
      overlay = "#545c66";
      muted = "#7c8a99";
      subtle = "#a9b8c4";
      fg = "#dbe4ea";
      fgBright = "#f2f6f9";
      accentBlue = "#6f97b8";
      accentRed = "#c1544a";
      accentYellow = "#d3a441";
      green = "#7a8f80";
      magenta = "#8b7ea0";
      cyan = "#8fb4c9";
    };
    description = "Shared cool blue-gray desktop palette.";
  };
}
