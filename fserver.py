import socket
from http.server import BaseHTTPRequestHandler, HTTPServer


def get_IP():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.connect(("8.8.8.8", 1))
    local_ip_address = s.getsockname()[0]
    return local_ip_address


class ReqHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-type", "text/html")
        self.end_headers()
        with open("index.html", "rb") as f:
            html = f.read()
        self.wfile.write(html)

    def do_POST(self):
        content_length = int(self.headers["Content-Length"])
        body = self.rfile.read(content_length)

        content_type = self.headers["Content-Type"]
        boundary = content_type.split("boundary=")[-1].encode()

        parts = body.split(b"--" + boundary)[1]
        header, _, content = parts.partition(b"\r\n\r\n")

        file_content = content.rsplit(b"\r\n")[0]

        filename = "file"
        for line in header.split(b"\r\n"):
            if b"Content-Disposition" in line and b"filename=" in line:
                filename = line.split(b'filename="')[1].rsplit(b'"')[0].decode()
                break

        with open(filename, "wb") as f:
            f.write(file_content)

        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"OK")


if __name__ == "__main__":
    HOSTNAME = ""
    PORT = 8080

    webServer = HTTPServer((HOSTNAME, PORT), ReqHandler)

    try:
        print("\nServer Started!!\n")
        print("local:   http://127.0.0.1:8080")
        print(f"public:  http://{get_IP()}:8080\n")
        webServer.serve_forever()
    except KeyboardInterrupt:
        pass

    webServer.server_close()
    print("Server closed!")
