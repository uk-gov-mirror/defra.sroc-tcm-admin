var CookiePolicy = (function () {
  var cookieName = 'cookie-message-seen'
  var cookieValue = 'Yes'

  function checkMessageCookie () {
    var cs = document.cookie ? document.cookie.split('; ') : []
    var n = cookieName + '='
    for (var i = 0; i < cs.length; i++) {
      var c = cs[i].trim()

      if (c.indexOf(n) === 0) {
        return c.substring(n.length, c.length) === cookieValue
      }
    }
    return false
  }

  function setMessageCookie () {
    var d = new Date()
    d.setYear(d.getFullYear() + 1)
    document.cookie = cookieName + '=' + cookieValue + ';path=/;expires=' + d.toUTCString()
  }

  function removeMessageCookie () {
    var cookie = cookieName + '=;path=/;expires=' + new Date(0).toUTCString()
    document.cookie = cookie
  }

  return {
    messageHasBeenSeen: checkMessageCookie,
    setMessageSeen: setMessageCookie,
    resetMessageSeen: removeMessageCookie
  }
})()

var $ = window.$

$(document).on('turbolinks:load', function () {
  if (CookiePolicy.messageHasBeenSeen()) {
    $('body').addClass('cookie-message-seen')
  } else {
    $('#cookie-message').on('closed.bs.alert', function () {
      CookiePolicy.setMessageSeen()
    })
  }
})
