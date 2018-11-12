var $ = window.$
//
// $(document).on('turbolinks:load', function () {
//   $('#view-mode').on('change', function () {
//     $('#page-number').val(1)
//     $(this).closest('form').trigger('submit')
//   })
// })
$(document).on('turbolinks:load', function () {
  $('.back-link').on('click', function (ev) {
    ev.preventDefault()
    history.back()
  })
})
