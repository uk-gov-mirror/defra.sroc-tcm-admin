var $ = window.$

$(document).on('turbolinks:load', function () {
  $('#per_page').on('change', function () {
    $('#page-number').val(1)
    $(this).closest('form').trigger('submit')
  })
})
