var hideButton, openEntry, showEmptyMessage, showEntry, showNextEntry;
openEntry = function(entry) {
  return chrome.tabs.getSelected(null, function(tab) {
    if (tab.url === entry.entry_url) {
      return;
    }
    return chrome.tabs.update(tab.id, {
      url: entry.entry_url
    });
  });
};
showEntry = function(entry, unread_count) {
  openEntry(entry);
  $('#title').text([entry.blog_title, entry.entry_title].join(' - '));
  $('#user_icon').empty().append($('<img>').attr({
    src: entry.user_image,
    title: entry.user_name
  }));
  $('#user_name').empty().append($('<a>').attr({
    href: "http://www.hatena.ne.jp/" + entry.user_name + "/"
  }).text(entry.user_name));
  $('#time_text').text(entry.time_text);
  return $('#unread_count').text(unread_count);
};
hideButton = function() {
  return $('#next-button').hide();
};
showEmptyMessage = function() {
  $('.small-info').hide();
  return $('#title').text('未読記事はありません');
};
showNextEntry = function() {
  return chrome.extension.sendRequest({
    method: "getNextEntry"
  }, function(res) {
    if (res.entry) {
      showEntry(res.entry, res.unread_count);
    }
    if (res.unread_count === 0) {
      hideButton();
    }
    if (!res.entry) {
      return showEmptyMessage();
    }
  });
};
$(function() {
  showNextEntry();
  $('#next-button').click(function() {
    showNextEntry();
    return false;
  });
  $('#user_name a').live('click', function() {
    chrome.tabs.create({
      url: $(this).attr('href')
    });
    return window.close();
  });
  return $('#next-button').focus();
});