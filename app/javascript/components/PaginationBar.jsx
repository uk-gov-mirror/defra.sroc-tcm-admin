import React from 'react'
import PaginationInfo from './PaginationInfo'
import PageSizeSelector from './PageSizeSelector'
import PageNavigator from './PageNavigator'
import Constants from './constants'

export default class PaginationBar extends React.Component {
  constructor (props) {
    super(props)

    this.onChangePageSize = this.onChangePageSize.bind(this)
    this.onChangePage = this.onChangePage.bind(this)
    this.onRequestExport = this.onRequestExport.bind(this)
  }

  onChangePageSize (size) {
    this.props.onChangePageSize(size)
  }

  onChangePage (page) {
    this.props.onChangePage(page)
  }

  onRequestExport (ev) {
    const pagination = this.props.pagination
    const limit = Constants.TRANSACTION_DOWNLOAD_LIMIT
    if (pagination.total_count > limit) {
      const msg = "There are " + pagination.total_count
        + " matching transactions but this export is limited to "
        + limit + " records.\n\nContinue anyway?"
      if (window.confirm(msg)) {
        this.props.onExportTransactions()
      }
    } else {
      this.props.onExportTransactions()
    }
  }

  renderNavigatorOrNot (pagination) {
    if (pagination.total_pages < 2) {
      return null
    }

    return (
      <div className='col-12 col-md-5'>
        <PageNavigator pagination={pagination} onChangePage={this.onChangePage} />
      </div>
    )
  }

  render () {
    const pagination = this.props.pagination
    const selectedPageSize = this.props.pageSize
    const pageSizes = [5, 10, 15, 25, 50]
    const matching = this.props.useMatchingLabel
    const showExportButton = this.props.showExportButton

    let exportButton = null
    if (showExportButton && pagination.total_count > 0) {
      exportButton = (
        <div className='ml-2 d-inline'>
          <button className='btn btn-sm btn-outline-secondary'
            title='Export matching entries'
            onClick={this.onRequestExport}>
            <span className='sr-only'>Export matching entries</span>
            <span className='oi oi-data-transfer-download' aria-hidden='true'></span>
          </button>
        </div>
      )
    }

    return (
      <div className='row paging-info'>
        <div className='col-12 col-md-4'>
          <PaginationInfo pagination={pagination} useMatchingLabel={matching} />
          {exportButton}
        </div>
        <div className='col-12 col-md-3 d-flex justify-content-lg-end mb-4'>
          <PageSizeSelector selectedPageSize={selectedPageSize}
            pageSizes={pageSizes} onChangeSize={this.onChangePageSize} />
        </div>
        { this.renderNavigatorOrNot(pagination) }
      </div>
    )
  }
}
