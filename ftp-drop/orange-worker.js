export default {
  async fetch(request) {
    const url = new URL(request.url);
    if (request.method === "GET" && (url.pathname === "/" || url.pathname === "/index.html")) {
      const src = await fetch("https://agency002com-ship-it.github.io/ftp-drop/120-index.html", {
        cf: { cacheTtl: 30 },
      });
      const html = await src.text();
      return new Response(html, {
        headers: {
          "content-type": "text/html; charset=utf-8",
          "cache-control": "no-store",
          "x-shift002": "orange",
        },
      });
    }
    return fetch(request);
  },
};
