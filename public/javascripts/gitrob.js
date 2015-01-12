$(document).ready(function() {

  $(".user-thumbnail").on('click', function(e) {
    e.preventDefault(); e.stopPropagation();
    var username = $(this).attr('data-username');
    var type     = $(this).attr('data-type');

    $.get('/ajax/users/' + username + '?type=' + type, function(html) {
      $("#user_modal .modal-body").html(html);
      $('#user_modal').modal({
        show: true
      });
    });
  });

  $("#blob_table tbody tr").on('click', function(e) {
    $("#blob_table tbody tr.active").removeClass('active');
    $(this).addClass('active loading');
    var blob_id = $(this).attr('data-blob-id');
    var t = $(this)

    $.get('/ajax/blobs/' + blob_id, function(html) {
      $("#blob_modal .modal-body").html(html);
      $("#blob_modal").modal({
        show: true
      });
      t.removeClass('loading');
      prettyPrint();
    });
  });

  $("#quick_filter").on('keyup', function(e) {
    var needles = this.value.split(" ");
    if ($("#only_with_findings").is(':checked')) {
      var rows = $(this).closest('table').find('tbody tr.warning');
    } else {
      var rows = $(this).closest('table').find('tbody tr');
    }

    if (this.value === '') {
      rows.show();
      $(this).closest('table').removeClass('table-striped').addClass('table-striped');
      return;
    }

    rows.hide();

    rows.filter(function(i, v) {
      var t = $(this);
      for (var d = 0; d < needles.length; ++d) {
        if (t.is(":contains('" + needles[d] + "')")) {
          return true;
        }
      }
      return false;
    }).show();
  });

  $("#only_with_findings").on('change', function() {
    if ($(this).is(':checked')) {
      onlyBlobsWithFindings();
    } else {
      $("#blob_table tbody tr").show();
    }
  });

  if ($('#only_with_findings').is(':checked')) {
    onlyBlobsWithFindings();
  }
});

function onlyBlobsWithFindings() {
  $("#blob_table tbody tr").hide();
  $("#blob_table tbody tr.warning").show();
}
