var $ = window.$

function init() {
  var container = $('.tcm-table')
  if (container.length > 0) {
    init_tcm_table(container)
    init_view_select(container)
    init_region_select(container)
    init_financial_year_select(container)
    init_search_form(container)
    init_page_nav(container)
    init_page_size(container)
    init_export_button(container)
    init_approve_all_button(container)
    init_generate_file_button(container)
    init_new_permit_category_button(container)
    init_row(container)
  }
}

function init_row(container) {
  init_category_select(container)
  init_temporary_cessation_select(container)
  init_show_details_button(container)
  init_approve_button(container)
  init_popups(container)
}

function reload_table(container) {
  var data = $(container).data()
  $.ajax({
    url: data.path,
    data: {
      search: data.search,
      page: data.page,
      per_page: data.perPage,
      sort: data.sortColumn,
      sort_direction: data.sortDirection,
      region: data.region,
      fy: data.financialYear
    },
    success: function (payload, status, xhr) {
      $(container).replaceWith(payload)
      init()
    },
    dataType: 'html'
  })
}

function approve_transactions(container) {
  var data = $(container).data()

  $.ajax({
    method: 'PUT',
    url: data.approvePath,
    data: {
      search: data.search,
      region: data.region,
    },
    success: function (payload, status, xhr) {
      console.log(payload)
      reload_table(container)
    },
    dataType: 'json'
  })
}

function export_table (container) {
  set_cookie_data(container)
  var data = $(container).data()
  var params = {
    search: data.search,
    sort: data.sortColumn,
    sort_direction: data.sortDirection,
    region: data.region,
    fy: data.financialYear
  }
  var path = data.path + '.csv?' + $.param(params)
  window.location.assign(path)
}

function fetch_summary_and_show (container) {
  var data = container.data()
  $.ajax({
    url: data.summaryPath,
    data: {
      region: data.region
    },
    success: function (payload, status, xhr) {
      $("#summary-dialog").replaceWith(payload)
      $("#summary-dialog").modal()
    },
    dataType: 'html'
  })
}

function set_cookie_data (container) {
  var data = $(container).data()
  document.cookie = "search=" + safe_val(data.search)
  document.cookie = "sort=" + safe_val(data.sortColumn)
  document.cookie = "sort_direction=" + safe_val(data.sortDirection)
  document.cookie = "region=" + safe_val(data.region)
  document.cookie = "fy=" + safe_val(data.financialYear)
  document.cookie = "page=" + safe_val(data.page)
  document.cookie = "per_page=" + safe_val(data.perPage)
}

function safe_val(val) {
  if (typeof val === 'undefined' || val == null) {
    return ''
  } else {
    return val
  }
}

function init_tcm_table (container) {
  container.find('.sort-link').on('click', function (ev) {
    var col = $(this).data('column')
    $(container).data('sort-column', col)

    if ($(this).hasClass('sorted')) {
      var d = $(container).data('sort-direction')
      if (d === 'asc') {
        d = 'desc'
      } else {
        d = 'asc'
      }
      $(container).data('sort-direction', d)
    }
    // revert to page 1 on reload
    container.data('page', 1)
    // do reload
    reload_table(container)

    ev.preventDefault()
  })
}

function init_view_select (container) {
  var select = container.find('select#mode')
  if (select.length > 0) {
    select.on('change', function (ev) {
      var selected = $(this).children(':selected')
      var url = selected.data('path') 
      var title = selected.text()
      $("#view-title").text(title)
      container.data('path', url)
      container.data('page', 1)
      reload_table(container)
    })
  } else {
    console.log("Didn't find view mode select")
  }
}

function init_region_select (container) {
  var select = container.find('select#region')
  if (select.length > 0) {
    select.on('change', function (ev) {
      container.data('region', $(this).val())
      container.data('page', 1)
      reload_table(container)
    })
  } else {
    console.log("Didn't find region select")
  }
}

function init_financial_year_select (container) {
  var select = container.find('select#fy')
  if (select.length > 0) {
    select.on('change', function (ev) {
      container.data('financial-year', $(this).val())
      container.data('page', 1)
      reload_table(container)
    })
  } else {
    console.log("Didn't find financial year select")
  }
}

function init_search_form (container) {
  var form = container.find("#search-bar")
  if (form.length) {
    form.on('submit', function (ev) {
      var val = form.find("input[name=search]").val()
      container.data('search', val)
      if (!container.hasClass('permit-categories')) {
        set_cookie_data(container)
      }
      reload_table(container)
      ev.preventDefault()
    })
  }
}

function init_page_nav (container) {
  container.find("li.page-item:not(.disabled):not(.active)>a.page-link").on('click', function (ev) {
    var pg = $(this).data('page')
    container.data('page', pg)
    set_cookie_data(container)
    reload_table(container)
    ev.preventDefault()
  })
}

function init_page_size (container) {
  container.find("select#per_page").on('change', function (ev) {
    container.data('per-page', $(this).val())
    container.data('page', 1)
    set_cookie_data(container)
    reload_table(container)
  })
}

function init_export_button (container) {
  container.find(".table-export-btn").on('click', function (ev) {
    export_table(container);
  })
}

function init_generate_file_button (container) {
  container.find(".generate-transaction-file-btn").on('click', function (ev) {
    console.log('generate file')
    fetch_summary_and_show(container)
    ev.preventDefault()
  })
}

function init_approve_all_button (container) {
  container.find(".approve-all-btn").on('click', function (ev) {
    console.log('approve all')
    approve_transactions(container)
    ev.preventDefault()
  })
}

function init_category_select (container) {
  var table = container.hasClass(".tcm-table") ? container : container.closest(".tcm-table")
  container.find(".tcm-select").tcmSelect()
    .on('tcm-select-change', function (ev, data) {
      var row = $(this).closest('tr')
      row.find("td:nth-last-child(2)").html("Working ...")
      update_row(row, table, { category: data.newValue })
    })
}

function init_temporary_cessation_select (container) {
  var table = container.hasClass(".tcm-table") ? container : container.closest(".tcm-table")
  container.find(".temporary-cessation-select").on('change', function (ev) {
    var row = $(this).closest('tr')
    row.find("td:nth-last-child(2)").html("Working ...")
    update_row(row, table, { temporary_cessation: $(this).val() })
  })
}

function update_row(row, table, data) {
  var id = row.attr('id')
  var path = table.data('path') + '/' + id
  console.log("update row: " + path)
  console.log(data)

  $.ajax({
    method: 'PUT',
    url: path,
    data: {
      transaction_detail: data
    },
    dataType: 'html',
    success: function (data) {
      row.replaceWith(data)
      var newRow = $("tr#" + id)
      init_row(newRow)
    }
  })
}

function init_show_details_button (container) {
  var table = container.hasClass(".tcm-table") ? container : container.closest(".tcm-table")
  container.find(".show-details-button").on('click', function (ev) {
    var path = $(this).data('path')
    set_cookie_data(table)
    window.location.assign(path)
  })
}

function init_approve_button (container) {
  var table = container.hasClass(".tcm-table") ? container : container.closest(".tcm-table")
  container.find(".approve-button").on('change', function (ev) {
    update_row($(this).closest('tr'), table,
      { approved_for_billing: $(this).is(":checked") })
  })
}

function init_popups (container) {
  container.find("[data-toggle='popover']").popover()
}

function init_new_permit_category_button (container) {
  container.find("button#new-category").on('click', function (ev) {
    var financialYear = container.data('financialYear')
    var path = $(this).data('path')
    window.location.assign(path + '?fy=' + financialYear)
  })
}

$(document).on('turbolinks:load', function () {
  init()
})
