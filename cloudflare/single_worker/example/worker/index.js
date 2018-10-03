addEventListener("fetch", event => {
  event.respondWith(handleRequest(event.request))
})


const makeResponse = ({ url, body }) => {
  return  url === "https://blog.beeceej.com/bundle.js"
        ? new Response(body, {
            status: 200,
            headers: { "content-type": "text/javascript" },
        })
        : new Response(body, {
            status: 200,
        })
}    

async function handleRequest(request) {
  const response = await fetch(request);
  return makeResponse(response);
}
