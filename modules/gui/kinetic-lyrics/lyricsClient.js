// Lyrics fetching for Kinetic Lyrics (Quickshell port).
//
// Derived from gnome-kinetic-lyrics by af44n (GPL-3.0), itself adapted from
// Dynamic Music Pill by Andbal23 (GPL-3.0). Rewritten for QML's XMLHttpRequest
// (callbacks instead of Promises) and hardened: every response is size-capped,
// provider-supplied URLs must be public https, and parsed output is clamped.
//
// SPDX-License-Identifier: GPL-3.0-or-later

.pragma library

var MAX_BYTES = 512 * 1024;
var MAX_LINES = 1500;
var MAX_TEXT = 300;
var MAX_WORDS = 80;
var TIMEOUT_MS = 8000;

// ---- http ---------------------------------------------------------------

function get(url, cb) {
    var xhr = new XMLHttpRequest();
    var done = false;
    function finish(v) {
        if (done)
            return;
        done = true;
        cb(v);
    }
    xhr.timeout = TIMEOUT_MS;
    xhr.onreadystatechange = function () {
        if (xhr.readyState === 3 && xhr.responseText.length > MAX_BYTES) {
            xhr.abort();
            finish(null);
        } else if (xhr.readyState === 4) {
            finish(xhr.status === 200 && xhr.responseText.length <= MAX_BYTES ? xhr.responseText : null);
        }
    };
    xhr.ontimeout = function () { finish(null); };
    xhr.onerror = function () { finish(null); };
    xhr.open("GET", url);
    xhr.send();
}

// URLs handed to us by a provider (lyricsUrl) are only followed when they are
// https and point at a public-looking hostname: no IP literals, localhost,
// userinfo or intranet suffixes.
function isSafeUrl(u) {
    if (typeof u !== "string")
        return false;
    var m = /^https:\/\/([^\/:?#@\[\]]+)(?::(\d+))?(?:[\/?#]|$)/i.exec(u);
    if (!m)
        return false;
    var host = m[1].toLowerCase();
    if (host.indexOf(".") < 0 || /^[\d.]+$/.test(host))
        return false;
    if (/(^|\.)(localhost|local|internal|lan|home|corp|intranet)$/.test(host))
        return false;
    if (m[2] && m[2] !== "443")
        return false;
    return true;
}

function firstOf(fns, cb) {
    var i = 0;
    function next() {
        if (i >= fns.length) {
            cb(null);
            return;
        }
        fns[i++](function (res) {
            if (res)
                cb(res);
            else
                next();
        });
    }
    next();
}

// ---- title / artist cleanup ---------------------------------------------

function cleanArtist(artist) {
    if (!artist)
        return "";
    return artist
        .replace(/\s*[-–—]\s*Topic$/i, "")
        .replace(/VEVO$/i, "")
        .replace(/\s+Official$/i, "")
        .trim();
}

var TAG_SUFFIX_RE = /^(?:remaster(?:ed)?|live|official.*|audio|video|music\s*video|lyric.*|visualizer|version|edit|mix|radio\s*edit|acoustic|instrumental|explicit|clean|\d{4}\b.*)/i;

function stripNoise(title) {
    return title
        .replace(/\s*[\(\[\{].*?[\)\]\}]/gi, "")
        .replace(/\s+(?:feat|ft|prod)\.?\s+.*/gi, "")
        .replace(/\s*\|\s*.*/g, "")
        .trim();
}

function cleanTitle(title, artist) {
    if (!title)
        return "";
    var t = stripNoise(title);
    var parts = t.split(/\s+[-–—]\s+/);
    if (parts.length >= 2) {
        var left = parts[0].trim();
        var right = parts.slice(1).join(" - ").trim();
        var cArt = cleanArtist(artist).toLowerCase();
        var l = left.toLowerCase();
        if (TAG_SUFFIX_RE.test(right))
            t = left;
        else if (cArt && (l === cArt || cArt.indexOf(l) >= 0 || l.indexOf(cArt) >= 0))
            t = right;
    }
    return t.trim() || title.trim();
}

function altArtistTitle(title, artist) {
    if (!title)
        return null;
    var parts = stripNoise(title).split(/\s+[-–—]\s+/);
    if (parts.length === 2) {
        var left = parts[0].trim();
        var right = parts[1].trim();
        if (left && right && !TAG_SUFFIX_RE.test(right)) {
            var cArt = cleanArtist(artist).toLowerCase();
            if (!cArt || left.toLowerCase() !== cArt)
                return {artist: left, title: right};
        }
    }
    return null;
}

function queryFor(title, artist) {
    var cArtist = cleanArtist(artist);
    var cleaned = cleanTitle(title, cArtist);
    var alt = altArtistTitle(title, cArtist);
    return {
        cArtist: cArtist,
        cleaned: cleaned || title,
        alt: alt,
        title: alt ? alt.title : (cleaned || title),
        artist: alt ? alt.artist : cArtist
    };
}

// ---- parsing ------------------------------------------------------------

function decodeEntities(s) {
    return s
        .replace(/&lt;/g, "<").replace(/&gt;/g, ">")
        .replace(/&quot;/g, "\"").replace(/&apos;/g, "'").replace(/&#39;/g, "'")
        .replace(/&amp;/g, "&");
}

function ttmlTimeToMs(val) {
    if (!val)
        return 0;
    var parts = String(val).trim().split(":");
    var n;
    if (parts.length === 1)
        n = parseFloat(parts[0]) * 1000;
    else if (parts.length === 2)
        n = (parseInt(parts[0]) * 60 + parseFloat(parts[1])) * 1000;
    else if (parts.length === 3)
        n = (parseInt(parts[0]) * 3600 + parseInt(parts[1]) * 60 + parseFloat(parts[2])) * 1000;
    else
        n = 0;
    return isFinite(n) ? Math.round(n) : 0;
}

// TTML is scanned with indexOf rather than lazy regexes over the whole
// document: provider responses are untrusted, and `<p begin=... ` repeated
// without a closing tag makes `[\s\S]*?</p>` quadratic or worse.
var MAX_TAG = 600;
var MAX_ELEMENTS = 20000;

function eachElement(s, name, fn) {
    var open = "<" + name;
    var close = "</" + name + ">";
    var pos = 0;
    for (var n = 0; n < MAX_ELEMENTS; n++) {
        var a = s.indexOf(open, pos);
        if (a < 0)
            return;
        var c = s.charAt(a + open.length);
        if (c !== " " && c !== ">" && c !== "\t" && c !== "\n" && c !== "\r") {
            pos = a + 1;
            continue;
        }
        var gt = s.indexOf(">", a);
        if (gt < 0 || gt - a > MAX_TAG) {
            pos = a + 1;
            continue;
        }
        var end = s.indexOf(close, gt);
        if (end < 0)
            return;
        fn(s.substring(a, gt + 1), s.substring(gt + 1, end));
        pos = end + close.length;
    }
}

function attr(tag, name) {
    var m = new RegExp("\\b" + name + "=\"([^\"]*)\"").exec(tag);
    return m ? m[1] : null;
}

// drop <span ttm:role="x-bg">...</span> (background vocals would create
// overlapping active lines), honouring nested spans
function stripBackground(body) {
    var out = "";
    var pos = 0;
    for (var n = 0; n < MAX_ELEMENTS; n++) {
        var a = body.indexOf("ttm:role=\"x-bg\"", pos);
        if (a < 0)
            break;
        var start = body.lastIndexOf("<span", a);
        if (start < pos)
            break;
        var depth = 1;
        var i = body.indexOf(">", a) + 1;
        while (depth > 0 && i > 0) {
            var o = body.indexOf("<span", i);
            var c = body.indexOf("</span>", i);
            if (c < 0) {
                i = body.length;
                break;
            }
            if (o >= 0 && o < c) {
                depth++;
                i = o + 5;
            } else {
                depth--;
                i = c + 7;
            }
        }
        out += body.substring(pos, start);
        pos = i;
    }
    return out + body.substring(pos);
}

function parseTTML(ttml) {
    var lines = [];
    eachElement(ttml, "p", function (tag, inner) {
        if (lines.length >= MAX_LINES)
            return;
        var begin = attr(tag, "begin");
        if (begin === null)
            return;
        var body = stripBackground(inner);
        var words = [];
        eachElement(body, "span", function (stag, sinner) {
            var sb = attr(stag, "begin");
            var wText = decodeEntities(sinner.replace(/<[^>]*>/g, "")).trim();
            if (sb !== null && wText && words.length < MAX_WORDS)
                words.push({time: ttmlTimeToMs(sb), text: wText});
        });
        var text = decodeEntities(body.replace(/<[^>]*>/g, "")).replace(/\s+/g, " ").trim();
        if (text)
            lines.push({time: ttmlTimeToMs(begin), text: text, words: words.length ? words : null});
    });
    lines.sort(function (a, b) { return a.time - b.time; });

    // merge lines that start at (nearly) the same moment
    var merged = [];
    lines.forEach(function (line) {
        var last = merged[merged.length - 1];
        if (last && Math.abs(last.time - line.time) < 100) {
            if (last.text.indexOf(line.text) < 0) {
                last.text += " " + line.text;
                if (line.words)
                    last.words = (last.words || []).concat(line.words);
            }
        } else {
            merged.push(line);
        }
    });
    return merged;
}

function parseLRC(input) {
    var lineRe = /\[(\d{2}):(\d{2})[.:](\d{2,3})\](.*)/;
    var wordRe = /[<(\[](\d{2}):(\d{2})[.:](\d{2,3})[>)\]]([^<(\[\n]*)/g;
    var out = [];
    var rows = input.split("\n");
    for (var r = 0; r < rows.length && out.length < MAX_LINES; r++) {
        var m = rows[r].match(lineRe);
        if (!m)
            continue;
        var time = parseInt(m[1]) * 60000 + parseInt(m[2]) * 1000 + parseFloat("0." + m[3]) * 1000;
        var body = m[4].trim();
        var words = [];
        var wm;
        wordRe.lastIndex = 0;
        while ((wm = wordRe.exec(body)) !== null && words.length < MAX_WORDS) {
            words.push({
                time: parseInt(wm[1]) * 60000 + parseInt(wm[2]) * 1000 + parseFloat("0." + wm[3]) * 1000,
                text: wm[4]
            });
        }
        var text = words.length ? body.replace(/[<(\[].*?[>)\]]/g, "").trim() : body;
        if (text)
            out.push({time: time, text: text, words: words.length ? words : null});
    }
    out.sort(function (a, b) { return a.time - b.time; });
    return out;
}

function parseJsonList(obj) {
    var list = obj && (obj.lines || obj.lyrics || obj.data || obj.result);
    if (!Array.isArray(list))
        return [];
    var out = [];
    for (var i = 0; i < list.length && out.length < MAX_LINES; i++) {
        var item = list[i];
        if (!item || typeof item !== "object")
            continue;
        var time = parseInt(item.startTimeMs || item.time || item.begin || 0);
        var text = String(typeof item.text === "string" ? item.text : (item.words || item.line || "")).trim();
        var sub = item.syllables || item.wordsArray || item.lead || item.words_list;
        var words = null;
        if (Array.isArray(sub) && sub.length) {
            words = sub.slice(0, MAX_WORDS).map(function (w) {
                return {time: parseInt(w.startTimeMs || w.time || w.begin || time), text: String(w.text || w.word || "")};
            });
        }
        if (text)
            out.push({time: time, text: text, words: words});
    }
    out.sort(function (a, b) { return a.time - b.time; });
    return out;
}

// Clamp whatever a provider gave us so the renderer never sees NaN timings,
// absurd line counts or megabyte-long lines.
function sanitize(lines) {
    var out = [];
    for (var i = 0; i < lines.length && out.length < MAX_LINES; i++) {
        var l = lines[i];
        if (!isFinite(l.time) || l.time < 0 || l.time > 86400000)
            continue;
        var text = String(l.text).slice(0, MAX_TEXT);
        var words = null;
        if (l.words) {
            words = l.words
                .filter(function (w) { return isFinite(w.time) && w.time >= 0; })
                .slice(0, MAX_WORDS)
                .map(function (w) { return {time: w.time, text: String(w.text).slice(0, MAX_TEXT)}; });
            if (!words.length)
                words = null;
        }
        out.push({time: l.time, text: text, words: words});
    }
    return out;
}

function parseLyrics(input) {
    if (!input)
        return [];
    var s = String(input);
    var lines = [];
    if (s.indexOf("<tt") >= 0 || s.indexOf("<p begin=") >= 0) {
        lines = parseTTML(s);
    } else if (s.trim().charAt(0) === "{") {
        try {
            var obj = JSON.parse(s);
            if (obj && typeof obj.ttml === "string")
                lines = parseTTML(obj.ttml);
            else
                lines = parseJsonList(obj);
        } catch (e) {
            lines = [];
        }
    }
    if (!lines.length)
        lines = parseLRC(s);
    return sanitize(lines);
}

function hasWords(lines) {
    return lines.some(function (l) { return l.words && l.words.length; });
}

// ---- providers ----------------------------------------------------------

function fromPayload(name, text) {
    var lines = parseLyrics(text);
    return lines.length ? {provider: name, lines: lines, wordLevel: hasWords(lines)} : null;
}

// Endpoint that returns lyrics directly, or a {results:[{lyricsUrl,...}]}
// index pointing at a TTML file.
function fetchIndexed(name, url, cb) {
    get(url, function (raw) {
        if (!raw) {
            cb(null);
            return;
        }
        var direct = fromPayload(name, raw);
        if (direct) {
            cb(direct);
            return;
        }
        var results;
        try {
            results = JSON.parse(raw).results;
        } catch (e) {
            cb(null);
            return;
        }
        if (!Array.isArray(results) || !results.length) {
            cb(null);
            return;
        }
        var best = null;
        for (var i = 0; i < results.length; i++) {
            if (results[i] && results[i].timing_type === "word") {
                best = results[i];
                break;
            }
        }
        best = best || results[0];
        if (!best || !isSafeUrl(best.lyricsUrl)) {
            cb(null);
            return;
        }
        get(best.lyricsUrl, function (ttml) { cb(ttml ? fromPayload(name, ttml) : null); });
    });
}

function trackQuery(base, q, album, duration) {
    var url = base + "?s=" + encodeURIComponent(q.title) + "&a=" + encodeURIComponent(q.artist);
    if (album)
        url += "&al=" + encodeURIComponent(album);
    if (duration > 0)
        url += "&d=" + Math.round(duration);
    return url;
}

var appleMusic = {
    name: "Apple Music",
    fetch: function (title, artist, album, duration, cb) {
        var q = queryFor(title, artist);
        var search = (q.title + " " + q.artist).trim();
        firstOf([
            function (next) { fetchIndexed("Apple Music", "https://lrc.red/api/v1?q=" + encodeURIComponent(search), next); },
            function (next) { fetchIndexed("Apple Music", trackQuery("https://lyrics-api.boidu.dev/getLyrics", q, album, duration), next); }
        ], cb);
    }
};

var biniLyrics = {
    name: "BiniLyrics",
    fetch: function (title, artist, album, duration, cb) {
        var q = queryFor(title, artist);
        var search = (q.title + " " + q.artist).trim();
        firstOf([
            function (next) { fetchIndexed("BiniLyrics", trackQuery("https://lyrics-api.binimum.org/getLyrics", q, album, duration), next); },
            function (next) { fetchIndexed("BiniLyrics", "https://lyrics-api.binimum.org/getLyrics?q=" + encodeURIComponent(search), next); }
        ], cb);
    }
};

var lrclib = {
    name: "LRCLib",
    fetch: function (title, artist, album, duration, cb) {
        var q = queryFor(title, artist);
        var queryTitle = q.cleaned;
        var jobs = [];

        function json(url, k) {
            get(url, function (raw) {
                var v = null;
                try { v = raw ? JSON.parse(raw) : null; } catch (e) { v = null; }
                k(v);
            });
        }
        function candidates(t, a, k) {
            var query = ((a || "") + " " + (t || "")).trim();
            if (!query) {
                k([]);
                return;
            }
            json("https://lrclib.net/api/search?q=" + encodeURIComponent(query), function (data) {
                if (!Array.isArray(data)) {
                    k([]);
                    return;
                }
                if (duration > 0) {
                    var close = data.filter(function (it) { return it && Math.abs((it.duration || 0) - duration) <= 15; });
                    if (close.length) {
                        k(close);
                        return;
                    }
                }
                k(data);
            });
        }

        if (duration > 0) {
            jobs.push(function (k) {
                json("https://lrclib.net/api/get?track_name=" + encodeURIComponent(queryTitle) +
                     "&artist_name=" + encodeURIComponent(q.cArtist) +
                     "&album_name=" + encodeURIComponent(album || "") +
                     "&duration=" + Math.round(duration), function (v) { k(v ? [v] : []); });
            });
        }
        jobs.push(function (k) { candidates(queryTitle, q.cArtist, k); });
        if (q.alt)
            jobs.push(function (k) { candidates(q.alt.title, q.alt.artist, k); });

        function runAll(list, k) {
            var pending = list.length;
            var all = [];
            list.forEach(function (job) {
                job(function (items) {
                    all = all.concat(items || []);
                    if (--pending === 0)
                        k(all);
                });
            });
        }

        function pick(items) {
            var seen = {};
            var best = null;
            var bestScore = -Infinity;
            items.forEach(function (it) {
                if (!it || typeof it.syncedLyrics !== "string" || seen[it.id])
                    return;
                seen[it.id] = true;
                var score = (duration > 0 && it.duration) ? -Math.abs(it.duration - duration) : 0;
                if (score > bestScore) {
                    bestScore = score;
                    best = it;
                }
            });
            return best ? fromPayload("LRCLib", best.syncedLyrics) : null;
        }

        runAll(jobs, function (items) {
            var res = pick(items);
            if (res || !queryTitle) {
                cb(res);
                return;
            }
            // artist may be a YouTube channel name: retry on the title alone
            candidates(queryTitle, "", function (more) { cb(pick(more)); });
        });
    }
};

var PROVIDERS = {"apple-music": appleMusic, "binilyrics": biniLyrics, "lrclib": lrclib};

// Ask every enabled provider at once; word-level beats line-synced, and Apple
// Music wins ties. cb(null) when nothing synced was found.
function getLyrics(title, artist, album, duration, providerIds, cb) {
    if (!(title && title.trim()) && !(artist && artist.trim())) {
        cb(null);
        return;
    }
    // MPRIS metadata is whatever a web page or file says it is
    title = String(title || "").slice(0, 200);
    artist = String(artist || "").slice(0, 200);
    album = String(album || "").slice(0, 200);
    var active = providerIds.map(function (id) { return PROVIDERS[id]; }).filter(function (p) { return !!p; });
    if (!active.length) {
        cb(null);
        return;
    }
    var pending = active.length;
    var results = [];
    active.forEach(function (p, order) {
        var settled = false;
        function settle(res) {
            if (settled)
                return;
            settled = true;
            if (res)
                results.push({res: res, order: order});
            if (--pending > 0)
                return;
            results.sort(function (a, b) { return a.order - b.order; });
            var words = results.filter(function (r) { return r.res.wordLevel; });
            var chosen = (words.length ? words : results)[0];
            cb(chosen ? chosen.res : null);
        }
        try {
            p.fetch(title, artist, album || "", duration || 0, settle);
        } catch (e) {
            settle(null);
        }
    });
}
