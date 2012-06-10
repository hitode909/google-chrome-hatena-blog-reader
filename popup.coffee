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

  $('#next-button').focus()