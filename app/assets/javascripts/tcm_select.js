(function ($) {
  $.fn.tcmSelect = function (options) {
    return this.each(function () {
      var wrapper = $(this)
      var control = wrapper.children(".tcm-select-control")
      var input = control.find(".tcm-select-input")
      var openBtn = control.find(".tcm-select-btn")
      var clearBtn = control.find(".tcm-select-clear-btn")
      var original = wrapper.children(".tcm-select-value")

      var elements = {
        wrapper: wrapper,
        original: original,
        control: control,
        input: input,
        openBtn: openBtn,
        clearBtn: clearBtn,
        mouseDown: false
      }

      input.on('focus', function (ev) {
        handleFocus(ev, elements)
      })

      input.on('blur', function (ev) {
        handleBlur(ev, elements)
      })

      input.on('click', function (ev) {
        if (!wrapper.hasClass('is-open')) {
          openList(elements)
        }
      })

      input.on('input propertychange', function (ev) {
        handleChange(ev, elements)
      })

      input.on('keydown', function (ev) {
        handleKeys(ev, elements)
      })

      wrapper.on('tcm-select-item-select', function (ev, item) {
        closeList(elements)
        setValue(elements, item.code)
        // input.trigger('focus')
        // console.log('item select: ' + ev.data)
      })

      openBtn.on('mousedown', function (ev) {
        input.trigger('focus')
        toggleList(ev, elements)
        ev.preventDefault()
        // elements.mouseDown = true
      })

      openBtn.on('mouseup', function (ev) {
        // elements.mouseDown = false
        ev.preventDefault()
      })

      // openBtn.on('click', function (ev) {
      //   console.log('btn click')
      // })

      clearBtn.on('mousedown', function (ev) {
        setValue(elements, '')
        // input.trigger('focus')
        // ev.preventDefault()
      })

      // clearBtn.on('mouseup', function (ev) {
      //   console.log('clear mouseup')
      //   // ev.preventDefault()
      // })
    })
  }

  function handleFocus(ev, elements) {
    elements.wrapper.addClass('has-focus')
  }

  function handleBlur(ev, elements) {
    // if (elements.mouseDown === false) {
      if (elements.wrapper.hasClass('is-open')) {
        cancelSelect(elements)
      }
      elements.wrapper.removeClass('has-focus')
    // }
  }

  function handleChange(ev, elements) {
    if (elements.wrapper.hasClass('is-open')) {
      refreshList(elements)
    } else {
      // should it be open then?
      openList(elements)
    }
  }

  function handleKeys(ev, elements) {
    if (elements.wrapper.hasClass('is-open')) {
      // up and down to navigate list
      // esc to cancel, enter to select
      switch(ev.which) {
        case 27:
          cancelSelect(elements)
          ev.preventDefault()
          break;
        case 38:
          moveUp(elements)
          ev.preventDefault()
          break;
        case 40:
          moveDown(elements)
          ev.preventDefault()
          break;
        case 13:
          selectFocussedItem(elements)
          break;
      }
    } else {
      if (ev.which == 40) { // cursor down
        openList(elements)
      }
    }
  }

  function selectFocussedItem (elements) {
    var item = $(".tcm-select-list-item.is-focussed")
    var data = null

    if (item.length > 0) {
      data = item.data()
    } else {
      item = $(".tcm-select-list-item.is-selected")
      if (item.length > 0) {
        data = item.data()
      }
    }
    if (data) {
      elements.wrapper.trigger('tcm-select-item-select', data)
    }
  }

  function setValue (elements, value) {
    data = {
      oldValue: elements.original.val(),
      newValue: value
    }

    elements.original.val(value)
    elements.input.val(value)

    // setTimeout(function () {
      elements.wrapper.trigger('tcm-select-change', data)
    // }, 50)
  }

  function reinstateValue (elements) {
    elements.input.val(elements.original.val())
  }

  function cancelSelect (elements) {
    reinstateValue(elements)
    closeList(elements)
  }

  function moveUp (elements) {
    var item = elements.list.find(".is-focussed")
    if (item.length === 0) {
      item = elements.list.find(".is-selected")
      if (item.length === 0) {
        item = $(".tcm-select-list-item:first")
      }
      item.addClass('is-focussed')
    } else {
      var i = parseInt(item.data('index'))
      if (i > 0) {
        item.removeClass("is-focussed")
        var prevItem = item.prev()
        prevItem.addClass('is-focussed')
        ensureVisible(prevItem)
      }
    }
  }

  function moveDown (elements) {
    var item = elements.list.find(".is-focussed")
    if (item.length === 0) {
      item = elements.list.find(".is-selected")
      if (item.length === 0) {
        item = $(".tcm-select-list-item:first")
      }
      item.addClass('is-focussed')
    } else {
      var count = parseInt(elements.list.data('count'))
      var i = parseInt(item.data('index'))
      if (i < count - 1) {
        item.removeClass("is-focussed")
        var nextItem = item.next()
        nextItem.addClass('is-focussed')
        ensureVisible(nextItem)
      }
    }
  }

  function toggleList (ev, elements) {
    if (elements.wrapper.hasClass('is-open')) {
      // close popup
      closeList(elements)
    } else {
      // show popup
      openList(elements)
    }
  }

  function openList (elements) {
    // initial open fetch all
    var el = elements.wrapper
    var data = el.data()
    // var q = elements.input.val()

    fetchCategories(elements, '', function (payload, status, xkr) {
        elements.wrapper.addClass('is-open')
        initList(elements, payload)
        if (elements.list.find(".tcm-select-list-item").length > 0) {
          var item = elements.list.find(".is-selected")
          if (item.length) {
            scrollToTop(item)
          } else {
            $("#tcm-select-list-item-0").addClass('is-focussed')
          }
        }
    })
  }

  function refreshList (elements) {
    var el = elements.wrapper
    var data = el.data()
    var q = elements.input.val()

    fetchCategories(elements, q, function (payload, status, xkr) {
        initList(elements, payload)
        if (elements.list.find(".tcm-select-list-item").length > 0) {
          $("#tcm-select-list-item-0").addClass('is-focussed')
        }
    })
  }

  function initList (elements, payload) {
    var val = elements.original.val()
    var list = makeList(payload, val)
    elements.list = list
    elements.wrapper.find(".tcm-select-list-wrapper").remove()
    elements.wrapper.append(list)
    var coll = $(".tcm-select-list-item")
    coll.hover(
      function () {
        $(".tcm-select-list-item").removeClass('is-focussed')
        $(this).addClass('is-focussed')
      },
      function () {
        $(this).removeClass('is-focussed')
      })
    coll.on('mousedown', function (ev) {
      if (!$(this).hasClass('nothing-found')) {
        var data = $(this).data()
        // elements.mouseDown = true
        elements.wrapper.trigger('tcm-select-item-select', data)
      }
      ev.preventDefault()
    }).on('mouseup', function (ev) {
      // elements.mouseDown = false
      ev.preventDefault()
    })
  }

  function closeList(elements) {
    elements.wrapper.removeClass('is-open')
    elements.list.hide()

    // var sel = elements.list.find(".is-selected")
    //
    // if (sel.length) {
    //   if (sel.hasClass('nothing-found')) {
    //     // reinstate original
    //     elements.input.val(elements.original.val())
    //   } else {
    //     var selectedVal = sel.text()
    //     elements.input.val(selectedVal)
    //     if (elements.original.val() !== selectedVal) {
    //       // emit change event
    //       // update original value
    //       elements.wrapper.trigger("tcm-select-change", { 
    //         oldValue: elements.original.val(),
    //         newValue: selectedVal })
    //       elements.original.val(selectedVal)
    //     }
    //   }
    // } else {
    //   // have they cleared the box
    //   if (elements.input.val() === '' && elements.original.val() !== '') {
    //       // emit change event
    //       // update original value
    //     elements.wrapper.trigger("tcm-select-change", { 
    //       oldValue: elements.original.val(),
    //       newValue: '' })
    //     elements.original.val('')
    //   } else {
    //     // reinstate original
    //     elements.input.val(elements.original.val())
    //   }
    // }
    elements.list.remove()
  }

  function fetchCategories (elements, query, successCallback) {
    var d = elements.wrapper.data()
    $.ajax({
      url: d.categoryPath,
      data: {
        fy: d.financialYear,
        q: query
      },
      success: successCallback,
      dataType: 'json'
    })
  }

  function makeList(data, selectedValue) {
    var outer = $("<div class='tcm-select-list-wrapper'></div>")
    var list = $("<div class='tcm-select-list' role='listbox' tabIndex='-1'></div>")
    var counter = 0
    data.forEach(function (c) {
      var s = $("<div class='tcm-select-list-item' role='option'"
        + "data-code='" + c.code + "' data-description='" + c.description
        + "' aria-label='" + c.code + "'>" + c.code + "<div class='item-desc'>"
        + c.description + "</div></div>")

      s.attr('id', "tcm-select-list-item-" + counter)
      if (selectedValue === c.code) {
        s.addClass('is-selected')
      }
      s.data('index', counter)
      list.append(s)
      counter++
    })
    if (counter === 0) {
      list.append("<div class='tcm-select-list-item nothing-found'>No matches</div>")
    }
    outer.append(list)
    outer.data('count', counter)
    return outer
  }

  function scrollToTop(item) {
    var parent = item.parent()
    parent.scrollTop(item.offset().top - parent.offset().top)
  }

  function ensureVisible(item) {
    var itemTop = item.offset().top
    var parent = item.parent()
    var parentTop = parent.offset().top
    var scrollTop = parent.scrollTop()
    var itemHeight = item.outerHeight()
    var parentBottom = parentTop + parent.height()

    if (itemTop < parentTop) {
      var offset = parentTop - itemTop
      parent.scrollTop(scrollTop - offset)
    } else if (itemTop + itemHeight > parentBottom) {
      var target = parentBottom - itemHeight
      var offset = itemTop - target
      parent.scrollTop(scrollTop + offset)
    }
  }
} (jQuery))
