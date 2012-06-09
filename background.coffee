INTERVAL = 1000 * 600

entryList = []

getLastVisitedEpoch = ->
  + localStorage['lastVisited'] || 0

setLastVisitedEpoch = (epoch) ->
  localStorage['lastVisited'] = epoch

updateEntryList = (callback) ->
  $.ajax
    url: 'http://blog.hatena.ne.jp/-/antenna'
    dataType: 'html'
    success: (res) ->

      if entryList.length > 0
        keyTime = entryList[entryList.length - 1].time
      else
        keyTime = getLastVisitedEpoch()

      # $.each と Array.reverse を組み合わせたので ごちゃっとしてる 旧→新 の順で見るため
      $($(res).find('ul.entry-list li').get().reverse()).each ->
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

setInterval ->
  checkNewBlogs()
, INTERVAL

checkNewBlogs()


chrome.extension.onRequest.addListener (request, sender, sendResponse) ->
  return if request.method != "getNextEntry"

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