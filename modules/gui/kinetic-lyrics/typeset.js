// Word styling, timing and row filling for Kinetic Lyrics.
// Ported from gnome-kinetic-lyrics (GPL-3.0) by af44n.
// SPDX-License-Identifier: GPL-3.0-or-later

.pragma library

var MAX_TOKENS = 40;

function tokens(text) {
    return text
        .split(/\s+/)
        .map(function (t) {
            return t.replace(/^[("“‘\[]+/, "").replace(/[,.;:!?"”’)\]]+$/, "");
        })
        .filter(function (t) { return t.length > 0; })
        .slice(0, MAX_TOKENS);
}

function letterCount(t) {
    return t.replace(/[\s.,;:!?"'“”‘’()\[\]{}\-–—…_*&@#\/\\]/g, "").length;
}

// One {script, size} per token: short words go script, the longest word is
// the hero, the rest are big or mid by length. Long lines shrink.
function styles(toks, cfg) {
    var lens = toks.map(letterCount);
    var shrink = Math.max(0.55, Math.min(1, 7 / toks.length));
    var hero = -1;
    lens.forEach(function (l, i) {
        if (l > cfg.scriptMaxLetters && (hero < 0 || l > lens[hero]))
            hero = i;
    });
    return toks.map(function (t, i) {
        if (lens[i] <= cfg.scriptMaxLetters && toks.length > 1)
            return {script: true, size: cfg.scriptSize * shrink};
        if (i === hero)
            return {script: false, size: cfg.heroSize * shrink};
        return {script: false, size: (lens[i] >= 5 ? cfg.bigSize : cfg.midSize) * shrink};
    });
}

// When each token appears (ms, absolute track time).
function times(line, toks, nextTime, spread) {
    if (line.words && line.words.length) {
        var joined = "";
        var starts = [];
        line.words.forEach(function (w) {
            starts.push([joined.length, w.time]);
            joined += w.text || "";
        });
        var out = [];
        var cursor = 0;
        var ok = true;
        for (var i = 0; i < toks.length; i++) {
            var at = joined.indexOf(toks[i], cursor);
            if (at < 0) {
                ok = false;
                break;
            }
            cursor = at + toks[i].length;
            var t = line.time;
            for (var s = 0; s < starts.length; s++) {
                if (starts[s][0] <= at)
                    t = starts[s][1];
                else
                    break;
            }
            out.push(t);
        }
        if (ok)
            return out;
    }
    var span = Math.max(600, Math.min((nextTime - line.time) * spread, 4500));
    return toks.map(function (_, i) {
        return line.time + (toks.length > 1 ? span * i / (toks.length - 1) : 0);
    });
}

function hash(str) {
    var h = 0;
    for (var i = 0; i < str.length; i++)
        h = (h * 31 + str.charCodeAt(i)) | 0;
    return Math.abs(h);
}

// Greedy row filling: returns arrays of token indexes.
function rows(widths, gap, maxW) {
    var out = [];
    var cur = [];
    var curW = 0;
    widths.forEach(function (w, i) {
        var need = w + (cur.length ? gap : 0);
        if (cur.length && curW + need > maxW) {
            out.push(cur);
            cur = [];
            curW = 0;
        }
        curW += w + (cur.length ? gap : 0);
        cur.push(i);
    });
    if (cur.length)
        out.push(cur);
    return out;
}
