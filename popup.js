var entryList, getAntenna, getUnreadCount, hideButton, openEntry, showEmptyMessage, showEntry, showNextEntry;
entryList = [];
getAntenna = function(callback) {
  return $.ajax({
    url: 'http://blog.hatena.ne.jp/-/antenna(kari)',
    dataType: 'html',
    success: function(res) {
      var items;
      $('#indicator').hide();
      items = [];
      $(res).find('ol.antenna li').each(function() {
        var entry_title, entry_titles;
        entry_titles = $(this).contents().filter(function() {
          return this.nodeType === 3 && this.textContent.match(/\S/);
        });
        if (entry_titles.length > 0) {
          entry_title = entry_titles[0].textContent;
        } else {
          entry_title = '■';
        }
        return items.push({
          blog_title: $(this).find('a').text(),
          entry_title: entry_title,
          entry_url: $(this).find('a').attr('href'),
          user_image: $(this).find('img').attr('src'),
          user_name: $(this).attr('data-author'),
          time: $(this).find('time').attr('data-epoch'),
          time_text: $(this).find('time').text()
        });
      });
      return callback(items.reverse());
    }
  });
};
getUnreadCount = function() {
  return entryList.length;
};
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
  return $('#follow_button a').live('click', function() {
    return chrome.tabs.getSelected(null, function(tab) {
      return chrome.tabs.create({
        url: "http://reader.livedoor.com/subscribe/?url=" + tab.url
      });
    });
  });
});