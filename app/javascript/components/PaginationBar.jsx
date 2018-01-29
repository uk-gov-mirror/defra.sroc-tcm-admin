import React from 'react'
import PaginationInfo from './PaginationInfo'
import PageSizeSelector from './PageSizeSelector'
import PageNavigator from './PageNavigator'

export default class PaginationBar extends React.Component {
  constructor (props) {
    super(props)

    this.onChangePageSize = this.onChangePageSize.bind(this)
    this.onChangePage = this.onChangePage.bind(this)
  }

  onChangePageSize (size) {
    this.props.onChangePageSize(size)
  }

  onChangePage (page) {
    this.props.onChangePage(page)
  }

  renderNavigatorOrNot (pagination) {
    if (pagination.total_pages < 2) {
      return null
    }

    return (
      <div className='col-12 col-md-4'>
        <PageNavigator pagination={pagination} onChangePage={this.onChangePage} />
      </div>
    )
  }

  render () {
    const pagination = this.props.pagination
    const selectedPageSize = this.props.pageSize
    const pageSizes = [5, 10, 15, 25, 50]
    const matching = this.props.useMatchingLabel

    return (
      <div className='row paging-info'>
        <div className='col-12 col-md-4'>
          <PaginationInfo pagination={pagination} useMatchingLabel={matching} />
        </div>
        <div className='col-12 col-md-4 justify-content-lg-end mb-4'>
          <PageSizeSelector selectedPageSize={selectedPageSize}
            pageSizes={pageSizes} onChangeSize={this.onChangePageSize} />
        </div>
        { this.renderNavigatorOrNot(pagination) }
      </div>
    )
  }
}
