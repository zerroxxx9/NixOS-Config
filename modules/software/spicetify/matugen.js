// Applies the wallpaper palette (rendered by matugen/set-wallpaper into
// ~/.local/state/matugen/spotify/colors.json and served on localhost by the
// spotify-colors user service) as Spicetify colour variables. Polls, so a new
// wallpaper recolours a running Spotify within a couple of seconds.
(async function matugenColors() {
  while (!Spicetify?.Platform) {
    await new Promise((r) => setTimeout(r, 200));
  }

  const URL = "http://127.0.0.1:8374/colors.json";
  const root = document.documentElement;
  let last = "";

  const triplet = (hex) => {
    const h = hex.replace("#", "");
    return [0, 2, 4].map((i) => parseInt(h.slice(i, i + 2), 16)).join(",");
  };

  async function tick() {
    try {
      const res = await fetch(URL, { cache: "no-store" });
      if (!res.ok) return;
      const body = await res.text();
      if (body === last) return;
      const colors = JSON.parse(body);
      last = body;
      for (const [name, value] of Object.entries(colors)) {
        if (!/^#[0-9a-f]{6}$/i.test(value)) continue;
        root.style.setProperty(`--spice-${name}`, value);
        root.style.setProperty(`--spice-rgb-${name}`, triplet(value));
      }
    } catch (e) {
      // Server not up yet or file mid-write: try again next tick.
    }
  }

  tick();
  setInterval(tick, 2000);
})();
