const path = require('path')
exports.handler = (event, context, callback) => {

  const {request} = event.Records[0].cf

  if (!path.extname(request.uri)) {
    request.uri = '/index.html'
  }

  callback(null, request)

}