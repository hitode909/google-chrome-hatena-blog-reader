var INTERVAL, checkNewBlogs, entryList, getLastVisitedEpoch, setLastVisitedEpoch, updateBadge, updateEntryList;
INTERVAL = 1000 * 30;
entryList = [];
getLastVisitedEpoch = function() {
  return +localStorage['lastVisited'] || 0;
};
setLastVisitedEpoch = function(epoch) {
  return localStorage['lastVisited'] = epoch;
};
updateEntryList = function(callback) {
  return $.ajax({
    url: 'http://blog.hatena.ne.jp/-/antenna(kari)',
    dataType: 'html',
    success: function(res) {
      var keyTime;
      if (entryList.length > 0) {
        keyTime = entryList[entryList.length - 1].time;
      } else {
        keyTime = getLastVisitedEpoch();
      }
      $($(res).find('ol.antenna li').get().reverse()).each(function() {
        var entry, entry_title, entry_titles;
        entry_titles = $(this).contents().filter(function() {
          return this.nodeType === 3 && this.textContent.match(/\S/);
        });
        if (entry_titles.length > 0) {
          entry_title = entry_titles[0].textContent;
        } else {
          entry_title = '■';
        }
        entry = {
          blog_title: $(this).find('a').text(),
          entry_title: entry_title,
          entry_url: $(this).find('a').attr('href'),
          user_image: $(this).find('img').attr('src'),
          user_name: $(this).attr('data-author'),
          time: +$(this).find('time').attr('data-epoch'),
          time_text: $(this).find('time').text()
        };
        if (entry.time > keyTime) {
          return entryList.push(entry);
        }
      });
      if (callback) {
        return callback();
      }
    }
  });
};
chrome.browserAction.setBadgeBackgroundColor({
  color: [56, 136, 218, 255]
});
updateBadge = function() {
  var label;
  label = entryList.length > 0 ? String(entryList.length) : "";
  return chrome.browserAction.setBadgeText({
    text: label
  });
};
checkNewBlogs = function() {
  return updateEntryList(function() {
    return updateBadge();
  });
};
setInterval(function() {
  return checkNewBlogs();
}, INTERVAL);
checkNewBlogs();
chrome.extension.onRequest.addListener(function(request, sender, sendResponse) {
  var entry, len;
  if (request.method !== "getNextEntry") {
    return;
  }
  if (entryList.length > 0) {
    entry = entryList.shift();
    len = entryList.length;
    setLastVisitedEpoch(entry.time);
    updateBadge();
    return sendResponse({
      entry: entry,
      unread_count: len
    });
  } else {
    return sendResponse({
      entry: null,
      unread_count: 0
    });
  }
});