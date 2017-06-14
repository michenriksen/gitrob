$(document).ready(function() {
  $(function () {
    $('[data-toggle="tooltip"]').tooltip()
  });

  if ($("#assessments_table_container").length === 1) {
    initializeAssessmentsTableEvents();
    setTimeout(function() {
      refreshAssessmentsTable();
    }, 5000);
  }

  if ($("#comparisons_table_container").length === 1) {
    initializeComparisonsTableEvents();
    setTimeout(function() {
      refreshComparisonsTable();
    }, 5000)
  }

  if ($("#falsePositive_table_container").length === 1) {
    initializeFalsePositiveTableEvents();
    setTimeout(function() {
      refreshFalsePositiveTable();
    }, 5000)
  }

  $("#new_assessment_button").on("click", function(e) {
    e.preventDefault();

    $("#assessment_targets").val("");
    $("#new_assessment_modal").modal({
      show: true
    });
    return false;
  });

  $("#new_assessment_modal").on('shown.bs.modal', function (e) {
    $("#assessment_targets").focus();
  });

  $("#new_assessment_form").on("submit", function(e) {
    e.preventDefault();
    $.ajax({
      url: "/assessments",
      type: "POST",
      data: $(this).serialize()
    });
    $("#new_assessment_modal").modal("hide");
    refreshAssessmentsTable();
    return false;
  });

  $("#new_falsePositive_form").on("submit", function (e) {
    e.preventDefault();
    $.ajax({
      url: "/falsePositive",
      type: "POST",
      data: $(this).serialize()
    });
    refreshFalsePositiveTable();
    return false;
  });

  $(".blob-link").on("click", function(e) {
    e.preventDefault();
    $("#blob_modal").modal({
      show: true
    });

    $("#blobs_table tbody tr").removeClass("active-blob-row");
    $(this).closest("tr").addClass("active-blob-row");

    $.get($(this).attr("href"), function(response) {
      if ($(response).find("#blob_content").length === 1) {
        var worker = new Worker("/js/highlight.worker.js");
        worker.onmessage = function(event) {
          $("#blob_modal_content").html(response);
          $("#blob_content").html(event.data);
          $("#blob_content").scrollTop(0);
          worker.terminate();
          markInterestingValues($("#blob_content"));
        }
        worker.postMessage($(response).find("#blob_content").html());
      } else {
        $("#blob_modal_content").html(response);
      }
    });
  });

  $("#blob_modal").on('hidden.bs.modal', function (e) {
    $("#blob_modal_content").html(blobModalPlaceholder);
  });

  $("div.owner").on("click", function(e) {
    e.preventDefault();

    $.get($(this).attr("data-href"), function(response) {
      $("#user_modal_content").html(response);
      $("#user_modal").modal({
        show: true
      });
    });
  });

  $("#quick_filter").on("keyup", function(e) {
    var rows        = $(this).closest("table").find("tbody tr.blob-row");
    var query       = $.trim($(this).val()).replace(/ +/g, ' ').toLowerCase();
    var onlyFlagged = false;
    if ($("#show_only_flagged_files").length === 1) {
      if ($("#show_only_flagged_files").is(":checked")) {
        onlyFlagged = true;
      }
    }

    rows.show().filter(function() {
        if (onlyFlagged && !$(this).hasClass("danger")) {
          return true;
        }
        var text = $(this).text().replace(/\s+/g, ' ').toLowerCase();
        return !~ text.indexOf(query);
    }).hide();
  });

  $("#show_only_flagged_files").on("click", function() {
    var rows = $(this).closest("table").find("tbody tr.blob-row");
    if ($(this).is(":checked")) {
      rows.show().filter(function() {
        if (!$(this).hasClass("danger")) {
          return true;
        } else {
          return false;
        }
      }).hide();
    } else {
      rows.show();
    }
  });
});

var blobModalPlaceholder = $("#blob_modal_content").html();
var csrfToken = $('meta[name="csrf-token"]').attr("content");
$.ajaxPrefilter(function(options, originalOptions, jqXHR) {
  var method = options.type.toLowerCase();
  if (method === "post" || method === "put" || method === "delete") {
    jqXHR.setRequestHeader('X-CSRF-Token', csrfToken);
  }
});

function refreshAssessmentsTable() {
  var refreshEndpoint = $("#assessments_table_container").attr("data-refresh-endpoint");
  if (typeof refreshEndpoint !== typeof undefined && refreshEndpoint !== false) {
    $.get(refreshEndpoint, function(result) {
      $("#assessments_table_container").html(result);
      initializeAssessmentsTableEvents();
      setTimeout(function() {
        refreshAssessmentsTable();
      }, 5000);
    });
  }
}

function refreshComparisonsTable() {
  var refreshEndpoint = $("#comparisons_table_container").attr("data-refresh-endpoint");
  if (typeof refreshEndpoint !== typeof undefined && refreshEndpoint !== false) {
    $.get(refreshEndpoint, function(result) {
      $("#comparisons_table_container").html(result);
      initializeComparisonsTableEvents();
      setTimeout(function() {
        refreshComparisonsTable();
      }, 5000)
    });
  }
}

function refreshFalsePositiveTable() {
  var refreshEndpoint = $("#falsePositive_table_container").attr("data-refresh-endpoint");
  if (typeof refreshEndpoint !== typeof undefined && refreshEndpoint !== false) {
    $.get(refreshEndpoint, function(result) {
      $("#falsePositive_table_container").html(result);
      initializeFalsePositiveTableEvents();
      setTimeout(function() {
        refreshFalsePositiveTable();
      }, 5000)
    });
  }
}

function initializeAssessmentsTableEvents() {
  $("table.assessments").on("click", "td.owners", function(e) {
    e.preventDefault();

    if (!$(this).closest("tr").hasClass("unfinished")) {
      window.location = $(this).attr("data-href");
    }
  });

  $("table.assessments").on("click", ".delete-assessment", function(e) {
    e.preventDefault();

    if (confirm("Are you sure you want to delete this assessment?")) {
      $.ajax({
        url: "/assessments/" + $(this).attr("data-assessment-id"),
        type: "DELETE"
      });

      $(this).closest("tr").fadeOut("fast", function() {
        $(this).remove();
      });
    }
    return false;
  });

  $("table.assessments").on("click", ".compare-assessments", function() {
    $.ajax({
      url: "/comparisons",
      type: "POST",
      data: "assessment_id=" + parseInt($(this).attr("data-assessment-id")) + "&other_assessment_id=" + parseInt($(this).attr("data-other-assessment-id"))
    });

    $(this).closest("tr").fadeOut("fast", function() {
      $(this).remove();
    });
    return false;
  });
}

function initializeFalsePositiveTableEvents() {
  $("table.falsePositive").on("click", ".delete-fingerprint", function(e) {
    e.preventDefault();

    if (confirm("Are you sure you want to delete this fingerprint?")) {
      $.ajax({
        url: "/false_positive/" + $(this).attr("data-assessment-id"),
        type: "DELETE"
      });

      $(this).closest("tr").fadeOut("fast", function() {
        $(this).remove();
      });
    }
    return false;
  });
}

function initializeComparisonsTableEvents() {
  $("table.comparisons").on("click", "td.owners", function(e) {
    e.preventDefault();

    if (!$(this).closest("tr").hasClass("unfinished")) {
      window.location = $(this).attr("data-href");
    }
  });

  $("table.comparisons").on("click", ".delete-comparison", function(e) {
    e.preventDefault();

    if (confirm("Are you sure you want to delete this comparison?")) {
      $.ajax({
        url: "/comparisons/" + $(this).attr("data-comparison-id"),
        type: "DELETE"
      });

      $(this).closest("tr").fadeOut("fast", function() {
        $(this).remove();
      });
    }
    return false;
  });
}

function markInterestingValues(element) {
  var haystack = $(element).html();
  var needles = [
    /((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))/gmi,
    /([a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*)/gmi,
    /((\w+:\/\/)([\da-z\.-]+)\.([a-z\.]{2,6}))/gmi,
    /(([a-z0-9]([-a-z0-9]*[a-z0-9])?\.)+((aero|arpa|a[cdefgilmnoqrstuwxz])|(biz|b[abdefghijmnorstvwyz])|(cat|com|coop|c[acdfghiklmnorsuvxyz])|d[ejkmoz]|(edu|e[ceghrstu])|f[ijkmor]|(gov|g[abdefghilmnpqrstuwy])|h[kmnrtu]|(info|int|i[delmnoqrst])|(jobs|j[emop])|k[eghimnprwyz]|l[abcikrstuvy]|(mil|mobi|museum|m[acdghklmnopqrstuvwxyz])|(name|net|n[acefgilopruz])|(om|org)|(pro|p[aefghklmnrstw])|qa|r[eouw]|s[abcdegijklmnortvyz]|(travel|t[cdfghjklmnoprtvwz])|u[agkmsyz]|v[aceginu]|w[fs]|y[etu]|z[amw]))/gm,
    /([a-f0-9\-\$\/]{32,})/gmi
  ];

  needles.forEach(function(needle) {
    haystack = haystack.replace(needle, "<mark>$1</mark>");
  });
  element.html(haystack);
}
