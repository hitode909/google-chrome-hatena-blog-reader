entryList = []

getAntenna = (callback) ->
  $.ajax
    url: 'http://blog.hatena.ne.jp/-/antenna(kari)'
    dataType: 'html'
    success: (res) ->
      $('#indicator').hide()
      items = []
      $(res).find('ol.antenna li').each ->
        entry_titles = $(this).contents().filter(-> this.nodeType == 3 && this.textContent.match(/\S/))
        if entry_titles.length > 0
          entry_title = entry_titles[0].textContent
        else
          entry_title = '■'
        items.push
          blog_title: $(this).find('a').text()
          entry_title: entry_title
          entry_url:   $(this).find('a').attr('href')
          user_image: $(this).find('img').attr('src')
          user_name: $(this).attr('data-author')
          time: $(this).find('time').attr('data-epoch')
          time_text: $(this).find('time').text()
      callback items.reverse()

getUnreadCount = ->
  entryList.length

openEntry = (entry) ->
  chrome.tabs.getSelected null, (tab) ->
    return if tab.url == entry.entry_url
    chrome.tabs.update tab.id, {url: entry.entry_url}

showEntry = (entry, unread_count) ->
  openEntry(entry)
  $('#title').text [entry.blog_title, entry.entry_title].join(' - ')
  $('#user_icon').empty().append $('<img>').attr(src: entry.user_image, title: entry.user_name)
  $('#user_name').empty().append $('<a>').attr(href: "http://www.hatena.ne.jp/#{entry.user_name}/").text(entry.user_name)
  $('#time_text').text(entry.time_text)
  $('#unread_count').text(unread_count)

  $('#follow_button a').text("...")

  chrome.extension.sendRequest
    method: "getBlogInfo"
    url: entry.entry_url
    , (res) ->
      isLoggedIn = res.isLoggedIn
      isSubscribing = res.isSubscribing
      count = res.count

      if isLoggedIn
        label = "購読"
        label += "済" if isSubscribing
        label += " (#{count} users)" if count
      else
        label = "LivedoorReaderで購読"
        $('#follow_button a').addClass 'not_logged_in'

      $('#follow_button a').text label


hideButton = ->
  $('#next-button').hide()

showEmptyMessage = ->
  $('.small-info').hide()
  $('#title').text('未読記事はありません')

showNextEntry = ->
  chrome.extension.sendRequest {method: "getNextEntry"}, (res) ->
    if res.entry
      showEntry(res.entry, res.unread_count)

    if res.unread_count == 0
      hideButton()

    if ! res.entry
      showEmptyMessage()

$ ->
  showNextEntry()

  $('#next-button').click ->
    showNextEntry()
    false

  $('#user_name a').live 'click', ->
    chrome.tabs.create
      url: $(this).attr('href')
    window.close()

  $('#follow_button a').live 'click', ->
    $('#follow_button a').css
      opacity: 0.5
    chrome.tabs.getSelected null, (tab) ->
      if $('#follow_button a.not_logged_in').length > 0
        chrome.tabs.create
          url: "http://reader.livedoor.com/subscribe/?url=#{encodeURIComponent(tab.url)}"
        window.close()
        return

      chrome.extension.sendRequest
        method: "subscribeBlog"
        url: tab.url
      , (res) ->
        $('#follow_button a').text '購読しました'
        $('#follow_button a').css
          opacity: 1.0

    false