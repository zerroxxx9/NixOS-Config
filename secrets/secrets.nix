# SSH Public Keys — diese Hosts/User dürfen die Secrets entschlüsseln.
#
# Host-Keys findest du mit: ssh-keyscan localhost
# Oder: cat /etc/ssh/ssh_host_ed25519_key.pub
#
# Deinen YubiKey FIDO2 SSH-Key findest du mit: cat ~/.ssh/id_ed25519_sk.pub
let
  # Dein persönlicher Schlüssel (YubiKey FIDO2 SSH oder normaler SSH-Key)
  # Wird zum Verschlüsseln/Re-Encrypting auf deinem Rechner gebraucht
  zerrox = "ssh-ed25519 AAAA... zerrox@work"; # ← ERSETZEN mit deinem Public Key
  # SSH Host-Key deines Arbeitsrechners (zum Entschlüsseln beim Boot)
  work = "ssh-ed25519 AAAA... root@work"; # ← ERSETZEN mit: cat /etc/ssh/ssh_host_ed25519_key.pub
  homelab = "ssh-ed25519 AAAA... root@homelab"; # SSH Host-key Homelab

  allUsers = [ zerrox ];
  allHosts = [ work homelab wsl ];
  workOnly = [ work ];
  homelabOnly = [ homelab ]
in {
  "tailscale-authkey.age".publicKeys = allUsers ++ homelabOnly;
  "wifi-passwords.age".publicKeys = allUsers ++ workOnly;
  "copilot-api-key.age".publicKeys = allUsers ++ workOnly;
  "brave-bookmarks.age".publicKeys = allUsers ++ workOnly;
}