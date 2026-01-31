import http.server
import socketserver
import os

PORT = 8080
DIRECTORY = "Android Frontend/Sentinel - Android/build/web"

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def do_GET(self):
        # 1. Check if the specific file exists (ignoring query params)
        clean_path = self.path.split('?')[0]
        path = clean_path.lstrip('/')
        full_path = os.path.join(DIRECTORY, path)
        
        # 2. If it exists as a file, serve it
        if os.path.isfile(full_path):
            super().do_GET()
            return

        # 3. If it is a directory and has index.html, serve it (default behavior)
        if os.path.isdir(full_path):
            if os.path.isfile(os.path.join(full_path, "index.html")):
                super().do_GET()
                return

        # 4. Fallback for SPA: serve index.html for any known "missing" path
        # that doesn't look like an asset (api, images, etc? No, let's just forceful fallback)
        self.path = '/index.html'
        super().do_GET()

print(f"Serving SPA at http://localhost:{PORT}")
with socketserver.TCPServer(("", PORT), Handler) as httpd:
    httpd.serve_forever()
