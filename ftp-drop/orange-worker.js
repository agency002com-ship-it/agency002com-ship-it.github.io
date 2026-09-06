function rewritePageUrls(html, host) {
  const page = "https://" + host + "/";
  const pageEl = "https://" + host + "/?el=1";
  return html
    .replace(
      /<link rel="canonical" href="https:\/\/[^\"]+" \/>/,
      '<link rel="canonical" href="' + page + '" />'
    )
    .replace(
      /<link rel="alternate" hreflang="en" href="https:\/\/[^\"]+" \/>/,
      '<link rel="alternate" hreflang="en" href="' + page + '" />'
    )
    .replace(
      /<link rel="alternate" hreflang="el" href="https:\/\/[^\"]+" \/>/,
      '<link rel="alternate" hreflang="el" href="' + pageEl + '" />'
    )
    .replace(
      /<meta property="og:url" content="https:\/\/[^\"]+" \/>/,
      '<meta property="og:url" content="' + page + '" />'
    )
    .replace(
      /"url": "https:\/\/(?:tonight\.|now\.|book\.|live\.|www\.)?120\.cash\/"/g,
      '"url": "' + page + '"'
    );
}

export default {
  async fetch(request) {
    const url = new URL(request.url);
    if (
      (request.method === "GET" || request.method === "HEAD") &&
      (url.pathname === "/" || url.pathname === "/index.html")
    ) {
      if (request.method === "HEAD") {
        return new Response(null, {
          status: 200,
          headers: {
            "content-type": "text/html; charset=utf-8",
            "cache-control": "no-store",
            "x-shift002": "orange",
          },
        });
      }
      const src = await fetch("https://agency002com-ship-it.github.io/ftp-drop/120-index.html", {
        cf: { cacheTtl: 30 },
      });
      const html = rewritePageUrls(await src.text(), url.hostname);
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
