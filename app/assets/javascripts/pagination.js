var $ = window.$

$(document).on('turbolinks:load', function () {
  $('#per-page-select').on('change', function () {
    $('#page-number').val(1)
    $(this).closest('form').trigger('submit')
  })
})
