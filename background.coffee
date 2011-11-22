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
      tempItems = []
      $(res).find('ol.antenna li').each ->
        entry_titles = $(this).contents().filter(-> this.nodeType == 3 && this.textContent.match(/\S/))
        if entry_titles.length > 0
          entry_title = entry_titles[0].textContent
        else
          entry_title = '■'
        tempItems.push
          blog_title: $(this).find('a').text()
          entry_title: entry_title
          entry_url:   $(this).find('a').attr('href')
          user_image: $(this).find('img').attr('src')
          user_name: $(this).attr('data-author')
          time: + $(this).find('time').attr('data-epoch')
          time_text: $(this).find('time').text()

      entryList = []
      lastVisited = getLastVisitedEpoch()
      for entry in tempItems
        if entry.time > lastVisited
          entryList.push(entry)

      # to 0 = old, last = new
      entryList.reverse()
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