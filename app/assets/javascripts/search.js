var $ = window.$

$(document).on('turbolinks:load', function () {
  $('#region-select').on('change', function () {
    $(this).closest('form').trigger('submit')
  })
})
