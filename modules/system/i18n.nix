{hostVariables, ...}: {
  i18n.defaultLocale = hostVariables.osLanguage;

  i18n.extraLocaleSettings = {
    LC_ADDRESS = hostVariables.keyboardLayout;
    LC_IDENTIFICATION = hostVariables.keyboardLayout;
    LC_MEASUREMENT = hostVariables.keyboardLayout;
    LC_MONETARY = hostVariables.keyboardLayout;
    LC_NAME = hostVariables.keyboardLayout;
    LC_NUMERIC = hostVariables.keyboardLayout;
    LC_PAPER = hostVariables.keyboardLayout;
    LC_TELEPHONE = hostVariables.keyboardLayout;
    LC_TIME = hostVariables.keyboardLayout;
  };
}
