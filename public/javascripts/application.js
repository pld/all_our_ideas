var Google = {
  gaSSDSLoad: function(acct) {
    var gaJsHost = (("https:" == document.location.protocol) ? "https://ssl." : "http://www."), pageTracker, s;
    s = document.createElement('script');
    s.src = gaJsHost + 'google-analytics.com/ga.js';
    s.type = 'text/javascript';
    s.onloadDone = false;
    function init () {
      pageTracker = _gat._getTracker(acct);
      pageTracker._trackPageview();
    }
    s.onload = function () {
      s.onloadDone = true;
      init();
    };
    s.onreadystatechange = function() {
      if (('loaded' === s.readyState || 'complete' === s.readyState) && !s.onloadDone) {
        s.onloadDone = true;
        init();
      }
    };
    document.getElementsByTagName('head')[0].appendChild(s);
  }
};
$(document).ready(function() {
  $([$("#logo-citp"), $("#logo-princeton"), $("#logo-open"), $("#logo-check")]).each(function(el) {
    $(this).bind("mouseover", function() {
      var str = $(this).attr("src");
      $(this).attr('src', str.replace(".jpg", "-down.jpg"));
    });
    $(this).bind("mouseout", function() {
      var str = $(this).attr("src");
      $(this).attr('src', str.replace("-down.jpg", ".jpg"));
    });
  });
  $(".votebox tr.prompt td.idea").each(function(el) {
    $(this).bind("click", function() {
      $([$(this).children(".round-filledfg"), $(this).children(".round-filled").children()]).each(function(el) {
        $(this).css("background", "#0B0");
        $(this).css("border-left", "1px solid #0B0");
        $(this).css("border-right", "1px solid #0B0");
      });
      $(this).unbind("mouseover")
      $(this).unbind("mouseout")
    });
    $(this).bind("mouseover", function() {
      $([$(this).children(".round-filledfg"), $(this).children(".round-filled").children()]).each(function(el) {
        $(this).css("background", "#2b88ad");
        $(this).css("border-left", "1px solid #2b88ad");
        $(this).css("border-right", "1px solid #2b88ad");
      });
    });
    $(this).bind("mouseout", function() {
      $([$(this).children(".round-filledfg"), $(this).children(".round-filled").children()]).each(function(el) {
        $(this).css("background", "#3198c1");
        $(this).css("border-left", "1px solid #3198c1");
        $(this).css("border-right", "1px solid #3198c1");
      });
    });
    $(this).bind("click", function() {
      window.location.href = $(this).find("a").attr("href");
    })
  });
  $("#item").bind("click", function() {
    if ($(this).attr("value") == $("#default_text").attr("value"))
      $(this).attr("value", "");
  });
  $("#item").bind("keyup", function() {
    var value = $(this).attr("value");
    var len = $(this).attr("maxlength");
    if (value.length > len) {
      $(this).attr("value", value.substr(0, len));
      $("#length_error").show();
      setTimeout(function() { $("#length_error").fadeOut(1000); }, 3000);
    }
  });
  $("#submit_btn").bind("mouseover", function() {
    var str = $(this).attr("src");
    $(this).attr('src', str.replace(".jpg", "-over.jpg"));
  });
  $("#submit_btn").bind("mouseout", function() {
    var str = $(this).attr("src");
    $(this).attr('src', str.replace("-over.jpg", ".jpg"));
  });

  $("#submit_btn").bind("mousedown", function() {
    var str = $(this).attr("src");
    if (str.indexOf("-over") == -1)
      $(this).attr('src', str.replace(".jpg", "-down.jpg"));
    else if(str.indexOf("-down") == -1)
      $(this).attr('src', str.replace("-over.jpg", "-down.jpg"));
  });
  $("#question_question_text").bind("click", function() {
    if ($(this).attr("value") == $("#default_text").attr("value"))
      $(this).attr("value", "");
  });
  $("#question_name").bind("click", function() {
    if ($(this).attr("value") == $("#default_text2").attr("value"))
      $(this).attr("value", "");
  });
  $("#question_question_ideas").bind("click", function() {
    if ($(this).html().match($("#default_text3").attr("value").substr(0,10)))
      $(this).html("");
  });
});
