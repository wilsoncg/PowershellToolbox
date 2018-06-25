function getAbsoluteUrl(url) {
    if (url.toLowerCase().indexOf('/tradingapi') == -1) {
        return "/TradingApi" + url;
    } else {
        return url;
    }
}

function getAbsoluteUrlWithJSONP(url) {
    var jsonpUrl = getAbsoluteUrl(url);
    if (jsonpUrl.indexOf('?') > 0) {
        jsonpUrl += "&callback=?";
    } else {
        jsonpUrl += "?callback=?";
    }
    return jsonpUrl;
}

var requestHeaders = {};

function setRequestHeader(headerName, headerValue) {
    requestHeaders[headerName] = headerValue;

    $.ajaxSetup({
        'beforeSend': function (xhr) {
            for (propertyName in requestHeaders) {
                xhr.setRequestHeader(propertyName, requestHeaders[propertyName]);
            }
        }
    });
}

function doGet(url, onSuccess, async) {
    async = typeof async !== 'undefined' ? async : false;
    addResult('GET:' + getAbsoluteUrl(url) + '<br/>');
    $.ajax({
        async: async,
        type: 'GET',
        url: getAbsoluteUrl(url),
        success: onSuccess || showResults
    });
}

function doPost(url, data, onSuccess) {
    if (url === '/session') {
        requestHeaders = { };
    }
    async = typeof async !== 'undefined' ? async : false;
    addResult('POST:' + getAbsoluteUrl(url) + ' with: ' + JSON.stringify(data));
    $.ajax({
        async: async,
        type: 'POST',
        contentType: 'application/json; charset=utf-8',
        url: getAbsoluteUrl(url),
        dataType: 'json',
        data: JSON.stringify(data),
        success: onSuccess || showResults
    });
}

function showResults(data, textCode) {
    addResult('Statuscode: ' + textCode);
    if (data != null) {
        addResult('Response: ' + JSON.stringify(data) + '<br/>');
    } else {
        addResult('Response: null <br />');
    }
}

function addResult(text) {
    $('#result').append('<option>' + text + '</option>');
}