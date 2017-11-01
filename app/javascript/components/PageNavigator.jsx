import React from 'react'

export default class PageNavigator extends React.Component {
  constructor(props) {
    super(props)
  }

  onChangePage(page, ev) {
    console.log('selected page: ' + page)
    ev.preventDefault()
    this.props.onChangePage(page)
  }

  makeItem(label, access_label, value, active = false) {
    const clz = (active) ? 'page-item active' : 'page-item'
    return (
      <li key={label} className={clz}>
        <a href='#' className='page-link' onClick={this.onChangePage.bind(this, value)}>
          <span aria-hidden='true'>{label}</span>
          <span className='sr-only'>{access_label}</span>
        </a>  
      </li>
    )
  }

  makeDisabledItem(label, access_label, key) {
    const k = (key === null || key === 'undefined') ? label : key
    return (
      <li key={k} className='page-item'>
        <span className='page-link disabled'>
          <span aria-hidden='true'>{label}</span>
          <span className='sr-only'>{access_label}</span>
        </span>
      </li>
    )
  }

  truncatedBeforeItem() {
    return this.makeDisabledItem('...', 'More items', 'before')
  }

  truncatedAfterItem() {
    return this.makeDisabledItem('...', 'More items', 'after')
  }

  firstLink(currentPage, pageCount) {
    if(currentPage === 1) {
      // &laquo; is \u00ab
      return this.makeDisabledItem('\u00ab', 'First')
    } else {
      return this.makeItem('\u00ab', 'First', 1)
    }
  }

  prevLink(currentPage, pageCount) {
    if(currentPage === 1) {
      // &lt; is \u003c
      return this.makeDisabledItem('\u003c', 'Previous')
    } else {
      return this.makeItem('\u003c', 'Previous', currentPage - 1)
    }
  }

  links(currentPage, pageCount) {
    const left_truncated = (currentPage > 3) ? this.truncatedBeforeItem(-1) : null
    const right_truncated = (currentPage < (pageCount - 3)) ? this.truncatedAfterItem(pageCount + 1) : null

    const start = Math.max(1, currentPage - 2) 
    const end = Math.min(pageCount, currentPage + 2)
    const pages = this.linkRange(currentPage, start, end)

    return (
      [left_truncated, pages, right_truncated]
    )
  }

  linkRange(current, start, end) {
    let range = []
    for(var n = start; n <= end; n++) {
      range[n] = this.makeItem(n, n, n, n === current)
    }
    return range
  }

  nextLink(currentPage, pageCount) {
    if(currentPage === pageCount) {
      // &gt; is \u003e
      return this.makeDisabledItem('\u003e', 'Next')
    } else {
      return this.makeItem('\u003e', 'Next', currentPage + 1)
    }
  }

  lastLink(currentPage, pageCount) {
    if(currentPage === pageCount) {
      // &raquo; is \u00bb
      return this.makeDisabledItem('\u00bb', 'Last')
    } else {
      return this.makeItem('\u00bb', 'Last', pageCount)
    }
  }

  render() {
    const pagination = this.props.pagination
    const currentPage = pagination.current_page
    const lastPage = pagination.total_pages

    return (
      <nav aria-label='Page navigation'>
        <ul className='pagination justify-content-lg-end'>
          {this.firstLink(currentPage, lastPage)}
          {this.prevLink(currentPage, lastPage)}
          {this.links(currentPage, lastPage)}
          {this.nextLink(currentPage, lastPage)}
          {this.lastLink(currentPage, lastPage)}
        </ul>
      </nav>
    )
  }
}
