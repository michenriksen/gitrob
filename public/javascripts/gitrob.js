$(document).ready(function() {

  $(".updateorg").on('click', function() {
    var org_id = $(this).attr('id');
    var data = {operation: 'update'};

    alert("Updating Organization...\nYou can continue to use Gitrob while the database is being updated.");

    $.ajax({
      async: false,
      type: 'GET',
      url: '/orgs/' + org_id,
      data: data
    });
  });

  $(".deleteorg").on('click', function() {
    var org_id = $(this).attr('id');
    var data = {operation: 'delete'};

    var conf = confirm("Are you sure you want to delete this organization?\n(This can't be undone!)");

    if (conf) {
      alert("Deleting Organization...\nPage will refresh when finished.");

      $.ajax({
        async: false,
        type: 'GET',
        url: '/orgs/' + org_id,
        data: data
      });
      
      location.reload();
    }
  });

  $("select").on('change', function() {
    var blob_status = $(this).val().toString();
    var blob_id = $(this).attr('id');

    var data = {blobstat: blob_status};

    $.get('/ajax/blobs/' + blob_id, data);
  });

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

  $("#blob_table tbody tr #blob_cell").on('click', function(e) {
    $("#blob_table tbody tr #blob_cell.active").removeClass('active');
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

  $(".check").on('change', function() {
    var checked = $(this).is(':checked');
    checkBox($(this).attr('id').slice(0, -3), checked);
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

function checkBox(flag, checked) {
   if (checked) {
      $("#blob_table tbody tr." + flag).show();
   }
   else {
      $("#blob_table tbody tr." + flag).hide();
   }
}

function onlyBlobsWithFindings() {
  $("#blob_table tbody tr").hide();
  $("#blob_table tbody tr.warning").show();
}
