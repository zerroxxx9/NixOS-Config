"""Serve one directory on 127.0.0.1 with CORS so the Spotify client can poll the
wallpaper palette (see matugen.js). Only the given directory is exposed."""
import http.server
import sys
from functools import partial

directory, port = sys.argv[1], int(sys.argv[2])


class Handler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Cache-Control", "no-store")
        super().end_headers()

    def log_message(self, *args):
        pass


http.server.ThreadingHTTPServer(("127.0.0.1", port), partial(Handler, directory=directory)).serve_forever()
