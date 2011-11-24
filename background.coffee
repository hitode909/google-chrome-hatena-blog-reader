INTERVAL = 1000 * 30

entryList = []

getLastVisitedEpoch = ->
  + localStorage['lastVisited'] || 0

setLastVisitedEpoch = (epoch) ->
  localStorage['lastVisited'] = epoch

updateEntryList = (callback) ->
  $.ajax
    url: 'http://blog.hatena.ne.jp/-/antenna(kari)'
    dataType: 'html'
    success: (res) ->

      if entryList.length > 0
        keyTime = entryList[entryList.length - 1].time
      else
        keyTime = getLastVisitedEpoch()

      # $.each と Array.reverse を組み合わせたので ごちゃっとしてる 旧→新 の順で見るため
      $($(res).find('ol.antenna li').get().reverse()).each ->
        entry_titles = $(this).contents().filter(-> this.nodeType == 3 && this.textContent.match(/\S/))
        if entry_titles.length > 0
          entry_title = entry_titles[0].textContent
        else
          entry_title = '■'
        entry =
          blog_title: $(this).find('a').text()
          entry_title: entry_title
          entry_url:   $(this).find('a').attr('href')
          user_image: $(this).find('img').attr('src')
          user_name: $(this).attr('data-author')
          time: + $(this).find('time').attr('data-epoch')
          time_text: $(this).find('time').text()

        if entry.time > keyTime
          entryList.push entry

      callback() if callback

chrome.browserAction.setBadgeBackgroundColor({color: [56,136, 218, 255]})

updateBadge = ->
  label = if entryList.length > 0 then String(entryList.length) else ""
  chrome.browserAction.setBadgeText
    text: label

checkNewBlogs = ->
  updateEntryList ->
    updateBadge()

getNextEntry = (request, sender, sendResponse) ->
  if entryList.length > 0
    entry = entryList.shift()
    len = entryList.length
    setLastVisitedEpoch(entry.time)
    updateBadge()
    sendResponse
      entry: entry
      unread_count: len

  else
    sendResponse
      entry: null
      unread_count: 0

subscribeBlog = (request, sender, sendResponse) ->
  $.ajax
    url: "http://reader.livedoor.com/subscribe/?url=#{encodeURIComponent(request.url)}"
    dataType: 'html'
    success: (res) ->
      form = $(res).find('form[action="/subscribe/"]')

      if form.length == 0
        sendResponse
          status: 'ng'

      $.ajax
        dataType: 'html'
        type: 'POST'
        url: "http://reader.livedoor.com/subscribe/"
        data: form.serialize()
        success: ->
          sendResponse
            status: 'ok'
        error: ->
          sendResponse
            status: 'ng'

getBlogInfo = (request, sender, sendResponse) ->
  $.ajax
    url: "http://reader.livedoor.com/subscribe/?url=#{encodeURIComponent(request.url)}"
    dataType: 'html'
    success: (res) ->
      doc = $(res)
      isLoggedIn = doc.find('form[action="/login/index"]').length == 0
      isSubscribing = doc.find('.subscribed').length > 0
      count = parseInt(doc.find('.subscriber_count a').text()) || 0

      sendResponse
        isLoggedIn: isLoggedIn
        isSubscribing: isSubscribing
        count: count


# ---------------------

setInterval ->
  checkNewBlogs()
, INTERVAL

checkNewBlogs()

chrome.extension.onRequest.addListener (request, sender, sendResponse) ->

  if request.method == "getNextEntry"
    getNextEntry request, sender, sendResponse

  if request.method == "subscribeBlog"
    subscribeBlog request, sender, sendResponse

  if request.method == "getBlogInfo"
    getBlogInfo request, sender, sendResponse