#!/bin/bash

set -e

SCRIPTS_DIR="$HOME/scripts"
SCRIPT_PATH="$SCRIPTS_DIR/fserver.py"
SHELL_RC="$HOME/.zshrc"

# Detect shell
if [ -n "$BASH_VERSION" ]; then
  SHELL_RC="$HOME/.bashrc"
fi

echo ""
echo "  Installing fserver..."
echo ""

# Create scripts directory
mkdir -p "$SCRIPTS_DIR"

# Write fserver.py
cat > "$SCRIPT_PATH" << 'PYEOF'
import http.server, os, socket

def get_local_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(('8.8.8.8', 80))
        return s.getsockname()[0]
    finally:
        s.close()

HTML = b'''<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>File Upload</title>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
    background: #fff;
    color: #111;
    min-height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 24px;
  }
  .card {
    width: 100%;
    max-width: 420px;
    border: 1px solid #e5e5e5;
    border-radius: 12px;
    padding: 36px 32px;
  }
  h1 { font-size: 1.2rem; font-weight: 600; margin-bottom: 6px; }
  p.sub { font-size: 0.85rem; color: #888; margin-bottom: 28px; }
  .drop-area {
    border: 2px dashed #ddd;
    border-radius: 8px;
    padding: 36px 20px;
    text-align: center;
    cursor: pointer;
    transition: border-color 0.2s, background 0.2s;
    margin-bottom: 16px;
  }
  .drop-area:hover, .drop-area.dragover { border-color: #111; background: #fafafa; }
  .drop-area svg { margin-bottom: 10px; opacity: 0.4; }
  .drop-area .label { font-size: 0.9rem; color: #555; }
  .drop-area .hint { font-size: 0.75rem; color: #aaa; margin-top: 4px; }
  #file-name {
    font-size: 0.82rem;
    color: #555;
    margin-bottom: 16px;
    min-height: 18px;
    text-align: center;
  }
  button {
    width: 100%;
    padding: 11px;
    background: #111;
    color: #fff;
    border: none;
    border-radius: 8px;
    font-size: 0.95rem;
    cursor: pointer;
    transition: background 0.2s;
  }
  button:hover { background: #333; }
  button:disabled { background: #ccc; cursor: default; }
  #status {
    margin-top: 16px;
    font-size: 0.85rem;
    text-align: center;
    min-height: 20px;
    color: #555;
  }
  #status.success { color: #2a9d4e; }
  #status.error { color: #e53e3e; }
  input[type=file] { display: none; }
</style>
</head>
<body>
<div class="card">
  <h1>Send a file</h1>
  <p class="sub">Uploads to ~/Downloads.</p>
  <form id="form" method="POST" enctype="multipart/form-data">
    <input type="file" name="f" id="file-input">
    <div class="drop-area" id="drop-area">
      <svg width="32" height="32" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" d="M3 16.5v2.25A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75V16.5m-13.5-9L12 3m0 0l4.5 4.5M12 3v13.5"/>
      </svg>
      <div class="label">Tap to choose a file</div>
      <div class="hint">or drag and drop here</div>
    </div>
    <div id="file-name"></div>
    <button type="submit" id="submit-btn" disabled>Upload</button>
    <div id="status"></div>
  </form>
</div>
<script>
  const drop = document.getElementById('drop-area');
  const input = document.getElementById('file-input');
  const label = document.getElementById('file-name');
  const btn = document.getElementById('submit-btn');
  const status = document.getElementById('status');
  const form = document.getElementById('form');

  drop.addEventListener('click', () => input.click());
  drop.addEventListener('dragover', e => { e.preventDefault(); drop.classList.add('dragover'); });
  drop.addEventListener('dragleave', () => drop.classList.remove('dragover'));
  drop.addEventListener('drop', e => {
    e.preventDefault(); drop.classList.remove('dragover');
    input.files = e.dataTransfer.files;
    updateLabel();
  });
  input.addEventListener('change', updateLabel);

  function updateLabel() {
    if (input.files[0]) {
      label.textContent = input.files[0].name;
      btn.disabled = false;
    }
  }

  form.addEventListener('submit', async e => {
    e.preventDefault();
    btn.disabled = true;
    status.textContent = 'Uploading...';
    status.className = '';
    try {
      const res = await fetch('/', { method: 'POST', body: new FormData(form) });
      if (res.ok) {
        status.textContent = 'Upload complete!';
        status.className = 'success';
        label.textContent = '';
        input.value = '';
      } else { throw new Error(); }
    } catch {
      status.textContent = 'Upload failed. Try again.';
      status.className = 'error';
    }
    btn.disabled = false;
  });
</script>
</body>
</html>'''

class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        self.wfile.write(HTML)

    def do_POST(self):
        length = int(self.headers['Content-Length'])
        data = self.rfile.read(length)
        boundary = data.split(b'\r\n')[0]
        parts = data.split(boundary)
        for part in parts:
            if b'filename=' in part:
                filename = part.split(b'filename="')[1].split(b'"')[0].decode()
                content = part.split(b'\r\n\r\n', 1)[1].rsplit(b'\r\n', 1)[0]
                open(filename, 'wb').write(content)
                break
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b'OK')

    def log_message(self, format, *args, **kwargs): pass

ip = get_local_ip()
port = 8080
downloads = os.path.expanduser('~/Downloads')
os.chdir(downloads)
print(f"\n  File Server running")
print(f"  Local:   http://localhost:{port}")
print(f"  Mobile:  http://{ip}:{port}\n")
print(f"  Saving files to: {downloads}\n")
http.server.HTTPServer(('', port), Handler).serve_forever()
PYEOF

# Add alias if not already present
if ! grep -q "alias fserver=" "$SHELL_RC"; then
  echo "" >> "$SHELL_RC"
  echo "# fserver - local file upload server" >> "$SHELL_RC"
  echo "alias fserver='python3 $SCRIPT_PATH'" >> "$SHELL_RC"
  echo "  Added alias to $SHELL_RC"
else
  echo "  Alias already exists in $SHELL_RC, skipping"
fi

echo ""
echo "  Done! Run this to activate:"
echo ""
echo "    source $SHELL_RC"
echo ""
echo "  Then just type: fserver"
echo ""
