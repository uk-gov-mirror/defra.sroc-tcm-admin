'use strict'

var $ = window.$

function init () {
  var container = $('.tcm-table')
  if (container.length > 0) {
    initTcmTable(container)
    initViewSelect(container)
    initRegionSelect(container)
    initFinancialYearSelect(container)
    initUnapproveCheckbox(container)
    initPrePostSelect(container)
    initStatusSelect(container)
    initSearchForm(container)
    initPageNav(container)
    initPageSize(container)
    initExportButton(container)
    initApproveAllButton(container)
    initGenerateFileButton(container)
    initNewPermitCategoryButton(container)
    initNewUserButton(container)
    initRegimeFilterSelect(container)
    initRoleFilterSelect(container)
    initRow(container)
    checkPermitCategoryCache(container)
  }

  container = $('.exclusion-zone')
  if (container.length > 0) {
    initExclusionZone(container)
  }
}

function initRow (container) {
  initCategorySelect(container)
  initTemporaryCessationSelect(container)
  initShowDetailsButton(container)
  initApproveButton(container)
  initPopups(container)
}

function reloadTable (container) {
  var data = $(container).data()
  setCookieData(container)

  $.ajax({
    url: data.path,
    data: {
      search: data.search,
      page: data.page,
      per_page: data.perPage,
      sort: data.sortColumn,
      sort_direction: data.sortDirection,
      region: data.region,
      fy: data.financialYear,
      unapproved: data.unapproved,
      regime: data.regime,
      role: data.role,
      prepost: data.prepost,
      status: data.status
    },
    success: function (payload, status, xhr) {
      $(container).replaceWith(payload)
      init()
    },
    dataType: 'html'
  })
}

function approveTransactions (container) {
  var data = $(container).data()

  $.ajax({
    method: 'PUT',
    url: data.approvePath,
    data: {
      search: data.search,
      region: data.region
    },
    success: function (payload, status, xhr) {
      reloadTable(container)
    },
    dataType: 'json'
  })
}

function exportTable (container) {
  setCookieData(container)
  var data = $(container).data()
  var params = {
    search: data.search,
    sort: data.sortColumn,
    sort_direction: data.sortDirection,
    region: data.region,
    unapproved: data.unapproved,
    fy: data.financialYear
  }
  var path = data.path + '.csv?' + $.param(params)
  window.location.assign(path)
}

function fetchSummaryAndShow (container) {
  var data = container.data()
  $.ajax({
    url: data.summaryPath,
    data: {
      region: data.region
    },
    success: function (payload, status, xhr) {
      $('#summary-dialog').replaceWith(payload)
      $('#summary-dialog #confirm:not(:disabled)').on('click', function (ev) {
        if ($(this).is(':checked')) {
          // enable generate button
          $('#summary-dialog input.file-generate-btn').prop('disabled', false)
        } else {
          // disable generate button
          $('#summary-dialog input.file-generate-btn').prop('disabled', true)
        }
      })
      $('#summary-dialog').modal()
    },
    dataType: 'html'
  })
}

function setCookieData (container) {
  var data = $(container).data()
  document.cookie = 'search=' + safeValue(data.search)
  document.cookie = 'sort=' + safeValue(data.sortColumn)
  document.cookie = 'sort_direction=' + safeValue(data.sortDirection)
  document.cookie = 'region=' + safeValue(data.region)
  document.cookie = 'fy=' + safeValue(data.financialYear)
  document.cookie = 'page=' + safeValue(data.page)
  document.cookie = 'per_page=' + safeValue(data.perPage)
  document.cookie = 'unapproved=' + safeValue(data.unapproved)
}

function safeValue (val) {
  if (typeof val === 'undefined' || val == null) {
    return ';path=/'
  } else {
    return val + ';path=/'
  }
}

function initTcmTable (container) {
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
    reloadTable(container)

    ev.preventDefault()
  })
}

function initViewSelect (container) {
  var select = container.find('select#mode')
  if (select.length > 0) {
    select.on('change', function (ev) {
      var selected = $(this).children(':selected')
      var url = selected.data('path')
      var title = selected.text()
      $('#view-title').text(title)
      container.data('path', url)
      container.data('page', 1)
      reloadTable(container)
    })
  }
}

function initRegionSelect (container) {
  var select = container.find('select#region')
  if (select.length > 0) {
    select.on('change', function (ev) {
      container.data('region', $(this).val())
      container.data('page', 1)
      reloadTable(container)
    })
  }
}

function initUnapproveCheckbox (container) {
  var cb = container.find('input#unapproved')
  if (cb.length > 0) {
    cb.on('change', function (ev) {
      container.data('unapproved', $(this).is(':checked'))
      container.data('page', 1)
      reloadTable(container)
    })
  }
}

function initFinancialYearSelect (container) {
  var select = container.find('select#fy')
  if (select.length > 0) {
    select.on('change', function (ev) {
      container.data('financial-year', $(this).val())
      container.data('page', 1)
      reloadTable(container)
    })
  }
}

function initPrePostSelect (container) {
  var select = container.find('select#prepost')
  if (select.length > 0) {
    select.on('change', function (ev) {
      container.data('prepost', $(this).val())
      container.data('page', 1)
      reloadTable(container)
    })
  }
}

function initStatusSelect (container) {
  var select = container.find('select#status')
  if (select.length > 0) {
    select.on('change', function (ev) {
      container.data('status', $(this).val())
      container.data('page', 1)
      reloadTable(container)
    })
  }
}

function initSearchForm (container) {
  var form = container.find('#search-bar')
  if (form.length) {
    form.on('submit', function (ev) {
      var val = form.find('input[name=search]').val().trim()
      container.data('search', val)
      container.data('page', 1)
      if (!container.hasClass('permit-categories') &&
        !container.hasClass('users') &&
        !container.hasClass('transactions-files') &&
        !container.hasClass('imported-transaction-files')) {
        setCookieData(container)
      }
      reloadTable(container)
      ev.preventDefault()
    })
  }
}

function initPageNav (container) {
  container.find('li.page-item:not(.disabled):not(.active)>a.page-link').on('click', function (ev) {
    var pg = $(this).data('page')
    container.data('page', pg)
    setCookieData(container)
    reloadTable(container)
    ev.preventDefault()
  })
}

function initPageSize (container) {
  container.find('select#per_page').on('change', function (ev) {
    container.data('per-page', $(this).val())
    container.data('page', 1)
    setCookieData(container)
    reloadTable(container)
  })
}

function initExportButton (container) {
  container.find('.accept-and-download-btn').on('click', function (ev) {
    exportTable(container)
    ev.preventDefault()
    $('#data-protection-dialog').modal('hide')
  })

  container.find('.table-export-btn').on('click', function (ev) {
    $('#data-protection-dialog').modal()
    ev.preventDefault()
  })
}

function initGenerateFileButton (container) {
  container.find('.generate-transaction-file-btn').on('click', function (ev) {
    // console.log('generate file')
    fetchSummaryAndShow(container)
    ev.preventDefault()
  })
}

function initApproveAllButton (container) {
  container.find('.approve-all-btn').on('click', function (ev) {
    // console.log('approve all')
    approveTransactions(container)
    ev.preventDefault()
  })
}

function initRegimeFilterSelect (container) {
  var select = container.find('select#regime')
  if (select.length > 0) {
    select.on('change', function (ev) {
      container.data('regime', $(this).val())
      container.data('page', 1)
      reloadTable(container)
    })
  }
}

function initRoleFilterSelect (container) {
  var select = container.find('select#role')
  if (select.length > 0) {
    select.on('change', function (ev) {
      container.data('role', $(this).val())
      container.data('page', 1)
      reloadTable(container)
    })
  }
}

function initCategorySelect (container) {
  var table = container.hasClass('.tcm-table') ? container : container.closest('.tcm-table')
  container.find('.tcm-select').tcmSelect()
    .on('tcm-select-change', function (ev, data) {
      var row = $(this).closest('tr')
      row.find('td:nth-last-child(2)').html('Working ...')
      updateRow(row, table, { category: data.newValue })
    })
}

function initTemporaryCessationSelect (container) {
  var table = container.hasClass('.tcm-table') ? container : container.closest('.tcm-table')
  container.find('.temporary-cessation-select').on('change', function (ev) {
    var row = $(this).closest('tr')
    row.find('td:nth-last-child(2)').html('Working ...')
    updateRow(row, table, { temporary_cessation: $(this).val() })
  })
}

function initExclusionZone (container) {
  // console.log("init exclusion zone")
  var dlg = container.find('.exclusion-dialog')
  if (dlg.length > 0) {
    container.find('.exclude-button').on('click', function (ev) {
      ev.preventDefault()
      // console.log('exclude transactions')
      dlg.modal()
    })
  }
}

function updateRow (row, table, data) {
  var id = row.attr('id')
  var path = table.data('path') + '/' + id

  $.ajax({
    method: 'PUT',
    url: path,
    data: {
      transaction_detail: data
    },
    dataType: 'html',
    success: function (data) {
      // reloading just the row is causing weird (focus?) problems in IE 11
      reloadTable(table)
      // row.replaceWith(data)
      // setTimeout(function () {
      //   var newRow = $("tr#" + id)
      //   initRow(newRow)
      //   console.log("after initRow")
      //   newRow.find('.approve-button').focus()
      //   // $("#search").focus()
      // }, 50)
    }
  })
}

function initShowDetailsButton (container) {
  var table = container.hasClass('.tcm-table') ? container : container.closest('.tcm-table')
  container.find('.show-details-button').on('click', function (ev) {
    var path = $(this).data('path')
    setCookieData(table)
    Turbolinks.visit(path)  // eslint-disable-line
  })
}

function initApproveButton (container) {
  var table = container.hasClass('.tcm-table') ? container : container.closest('.tcm-table')
  container.find('.approve-button').on('change', function (ev) {
    updateRow($(this).closest('tr'), table,
      { approved_for_billing: $(this).is(':checked') })
  })
}

function initPopups (container) {
  container.find("[data-toggle='popover']").popover()
}

function initNewPermitCategoryButton (container) {
  container.find('button#new-category').on('click', function (ev) {
    var financialYear = container.data('financialYear')
    var path = $(this).data('path')
    window.location.assign(path + '?fy=' + financialYear)
  })
}

function initNewUserButton (container) {
  container.find('button#new-user').on('click', function (ev) {
    var path = $(this).data('path')
    window.location.assign(path)
  })
}

function checkPermitCategoryCache (container) {
  var ts = container.data('permit-category-timestamp')
  if (ts) {
    var lastChange = parseInt(ts)
    var regimePart = container.data('path').split('/').slice(0, 3).join('/')
    var length = window.sessionStorage.length
    var keysToClear = []
    for (var n = 0; n < length; n++) {
      var key = window.sessionStorage.key(n)
      if (key.startsWith(regimePart)) {
        var val = JSON.parse(window.sessionStorage.getItem(key))
        if (val.timestamp) {
          if (parseInt(val.timestamp) < lastChange) {
            console.log('cache: removing stale data ' + key)
            keysToClear.push(key)
          }
        } else {
          keysToClear.push(key)
        }
      }
    }

    for (n = 0; n < keysToClear.length; n++) {
      window.sessionStorage.removeItem(keysToClear[n])
    }
  }
}

$(document).on('turbolinks:load', function () {
  init()
})
