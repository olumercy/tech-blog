async function handler(event) {
    const request = event.request;
    let uri = request.uri;

    // Append 'index.html' if the URI ends with '/' or lacks a file extension
    if (uri.endsWith('/')) {
        uri += 'index.html';
    } else if (!uri.includes('.')) {
        uri += '/index.html';
    }

    // Update the request URI with the modified value
    request.uri = uri;
    
    return request;
}
