const http = require("http");
const fs = require("fs");
const path = require("path");

const PORT = process.env.PORT || 3000;

const MIME = {
  ".html": "text/html; charset=utf-8",
  ".css": "text/css",
  ".js": "application/javascript",
  ".json": "application/json",
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".gif": "image/gif",
  ".svg": "image/svg+xml",
  ".ico": "image/x-icon",
  ".woff": "font/woff",
  ".woff2": "font/woff2",
  ".ttf": "font/ttf",
  ".webp": "image/webp",
  ".mp4": "video/mp4",
};

http.createServer((req, res) => {
  let filePath = "." + decodeURIComponent(req.url.split("?")[0]);
  if (filePath === "./") filePath = "./index.html";

  const ext = path.extname(filePath).toLowerCase();

  if (ext && fs.existsSync(filePath)) {
    const contentType = MIME[ext] || "application/octet-stream";
    fs.readFile(filePath, (err, data) => {
      if (err) { res.writeHead(500); res.end("Error"); return; }
      res.writeHead(200, { "Content-Type": contentType });
      res.end(data);
    });
  } else {
    fs.readFile("./index.html", (err, data) => {
      if (err) { res.writeHead(500); res.end("Error"); return; }
      res.writeHead(200, { "Content-Type": "text/html; charset=utf-8" });
      res.end(data);
    });
  }
}).listen(PORT, () => {
  console.log("Server running on port " + PORT);
});
