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
  $('#unread_count').text(unread_count);
  $('#follow_button a').text("...");
  return chrome.extension.sendRequest({
    method: "getBlogInfo",
    url: entry.entry_url
  }, function(res) {
    var count, isLoggedIn, isSubscribing, label;
    isLoggedIn = res.isLoggedIn;
    isSubscribing = res.isSubscribing;
    count = res.count;
    if (isLoggedIn) {
      label = "購読";
      if (isSubscribing) {
        label += "済";
      }
      if (count) {
        label += " (" + count + " users)";
      }
    } else {
      label = "LivedoorReaderで購読";
      $('#follow_button a').addClass('not_logged_in');
    }
    return $('#follow_button a').text(label);
  });
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
    $('#follow_button a').css({
      opacity: 0.5
    });
    chrome.tabs.getSelected(null, function(tab) {
      if ($('#follow_button a.not_logged_in').length > 0) {
        chrome.tabs.create({
          url: "http://reader.livedoor.com/subscribe/?url=" + (encodeURIComponent(tab.url))
        });
        window.close();
        return;
      }
      return chrome.extension.sendRequest({
        method: "subscribeBlog",
        url: tab.url
      }, function(res) {
        $('#follow_button a').text('購読しました');
        return $('#follow_button a').css({
          opacity: 1.0
        });
      });
    });
    return false;
  });
});