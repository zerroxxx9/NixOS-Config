# Recipients, die agenix-Secrets entschl?sseln d?rfen.
#
# Sicher im Repo:
# - age-Recipients (age1...)
# - SSH Public Keys (*.pub)
#
# Niemals im Repo:
# - private SSH keys
# - age-plugin-yubikey Identit?ten
#
# Erwartete committed Dateien:
# - recipients/zerrox-yubikey.age.pub
# - recipients/work-ssh-host-ed25519.pub
# - recipients/homelab-ssh-host-ed25519.pub
#
# Optionaler Fallback-Admin-Key:
# - recipients/zerrox-admin-ssh-ed25519.pub
let
  readRecipient = path:
    builtins.replaceStrings ["\r" "\n"] ["" ""] (builtins.readFile path);

  optionalRecipient = path:
    if builtins.pathExists path then
      [ (readRecipient path) ]
    else
      [ ];

  requiredRecipient = name: path:
    if builtins.pathExists path then
      readRecipient path
    else
      throw "Missing recipient file for ${name}: ${toString path}";

  adminRecipients =
    let
      recipients =
        optionalRecipient ./recipients/zerrox-yubikey.age.pub
        ++ optionalRecipient ./recipients/zerrox-admin-ssh-ed25519.pub;
    in
      if recipients != [ ] then
        recipients
      else
        throw ''
          No admin recipient configured.
          Add at least one of:
            - secrets/recipients/zerrox-yubikey.age.pub
            - secrets/recipients/zerrox-admin-ssh-ed25519.pub
        '';

  workHost = requiredRecipient "work host SSH public key" ./recipients/work-ssh-host-ed25519.pub;
  homelabHost = requiredRecipient "homelab host SSH public key" ./recipients/homelab-ssh-host-ed25519.pub;
in
{
  "tailscale-authkey.age".publicKeys = adminRecipients ++ [ homelabHost ];
  "wifi-passwords.age".publicKeys = adminRecipients ++ [ workHost ];
  "copilot-api-key.age".publicKeys = adminRecipients ++ [ workHost ];
  "brave-bookmarks.age".publicKeys = adminRecipients ++ [ workHost ];
}
