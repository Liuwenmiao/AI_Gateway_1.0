#!/usr/bin/env python3
import http.server
import socketserver
import urllib.request
import urllib.parse
import json
import sys

class QwenProxyHandler(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        if self.path == '/compatible-mode/v1/chat/completions':
            try:
                # Read the request body
                content_length = int(self.headers.get('Content-Length', 0))
                request_body = self.rfile.read(content_length)
                
                # Forward to real Qwen API
                qwen_url = 'https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions'
                
                # Create request to Qwen API
                req = urllib.request.Request(qwen_url, data=request_body)
                
                # Copy headers
                for header_name, header_value in self.headers.items():
                    if header_name.lower() not in ['host', 'content-length']:
                        req.add_header(header_name, header_value)
                
                req.add_header('Content-Type', 'application/json')
                
                # Make request to Qwen API
                with urllib.request.urlopen(req, timeout=30) as response:
                    response_data = response.read()
                    
                    # Send response back
                    self.send_response(response.status)
                    for header_name, header_value in response.headers.items():
                        if header_name.lower() not in ['transfer-encoding', 'connection']:
                            self.send_header(header_name, header_value)
                    self.end_headers()
                    self.wfile.write(response_data)
                    
            except Exception as e:
                print(f"Error: {e}")
                # Send error response
                self.send_response(500)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                error_response = json.dumps({"error": str(e)}).encode()
                self.wfile.write(error_response)
        else:
            self.send_response(404)
            self.end_headers()
    
    def log_message(self, format, *args):
        print(f"[PROXY] {format % args}")

if __name__ == '__main__':
    PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8888
    
    with socketserver.TCPServer(("", PORT), QwenProxyHandler) as httpd:
        print(f"Qwen proxy server running at http://0.0.0.0:{PORT}")
        print("Forwarding requests to https://dashscope.aliyuncs.com")
        httpd.serve_forever() 