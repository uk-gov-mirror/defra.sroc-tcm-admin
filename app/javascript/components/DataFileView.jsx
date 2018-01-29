import React from 'react'
import axios from 'axios'
import DataFileSummary from './DataFileSummary'
import TransactionTable from './TransactionTable'
import PaginationBar from './PaginationBar'

export default class DataFileView extends React.Component {
  constructor (props) {
    super(props)
    const errorList = this.props.errors

    this.state = {
      sortColumn: this.props.sortColumn,
      sortDirection: this.props.sortDirection,
      status: this.props.status,
      successCount: this.props.successCount,
      failedCount: this.props.failedCount,
      errorList: errorList,
      pageSize: errorList.pagination.per_page,
      currentPage: errorList.pagination.current_page,
    }

    this.toggleSortDirection = this.toggleSortDirection.bind(this)
    this.changeSortColumn = this.changeSortColumn.bind(this)
    this.changePage = this.changePage.bind(this)
    this.changePageSize = this.changePageSize.bind(this)

    this.cleanUp = this.cleanUp.bind(this)
  }

  emptyErrorList () {
    const perPage = 10
    return {
      pagination: {
        per_page: perPage,
        current_page: 1
      },
      // NOTE: we need a polyfill for Array.prototype.fill on IE
      errors: new Array(perPage).fill().map((_, i) => { return { id: i } })
    }
  }

  toggleSortDirection () {
    const direction = this.state.sortDirection === 'asc' ? 'desc' : 'asc'
    this.setState({sortDirection: direction, currentPage: 1}, () => {
      this.fetchSummaryData()
    })
  }

  changeSortColumn (columnName) {
    this.setState({sortColumn: columnName, sortDirection: 'asc', currentPage: 1}, () => {
      this.fetchSummaryData()
    })
  }

  changePage (page) {
    this.setState({currentPage: page}, () => {
      this.fetchSummaryData()
    })
  }

  changePageSize (size) {
    this.setState({pageSize: size}, () => {
      this.fetchSummaryData()
    })
  }

  unloadEventName () {
    return (typeof Turbolinks !== 'undefined') ? 'turbolinks:before-render' : 'beforeunload'
  }

  componentDidMount () {
    this.checkStatusAndRefresh()
    window.addEventListener(this.unloadEventName(), this.cleanUp)
  }

  componentWillUnmount () {
    console.log('in unmount')
    this.cleanUp()
  }

  cleanUp () {
    console.log('Cleaning up')
    window.removeEventListener(this.unloadEventName(), this.cleanUp)
    if (this.state.timerId) {
      console.log('clearing timer')
      clearTimeout(this.state.timerId)
      this.setState({timerId: null})
    }
  }

  checkStatusAndRefresh () {
    if (/Uploaded|Processing/.test(this.state.status)) {
      console.log('fetching data')
      this.fetchSummaryData()
      let timer = setTimeout(this.checkStatusAndRefresh.bind(this), 1000)
      this.setState({timerId: timer})
    }
  }

  fetchSummaryData () {
    axios.get(this.props.path, {
      params: {
        sort: this.state.sortColumn,
        sort_direction: this.state.sortDirection,
        page: this.state.currentPage,
        per_page: this.state.pageSize
      }
    })
      .then(res => {
        const errorList = res.data.error_list

        this.setState({
          status: res.data.status,
          successCount: res.data.success_count,
          failedCount: res.data.failed_count,
          errorList: errorList,
          pagination: errorList.pagination,
          pageSize: errorList.pagination.per_page,
          currentPage: errorList.pagination.current_page
        })
      })
      .catch(error => {
        // TODO: handle this
        console.log(error)
        throw error
      })
  }

  render () {
    const regime = this.props.regime
    const filename = this.props.filename
    const uploadDate = this.props.uploadDate
    const status = this.state.status
    const successCount = this.state.successCount
    const failedCount = this.state.failedCount
    const columns = this.props.columns
    const sortColumn = this.state.sortColumn
    const sortDirection = this.state.sortDirection
    const errorList = this.state.errorList
    const pagination = errorList.pagination
    const currentPage = this.state.currentPage
    const pageSize = this.state.pageSize
    const summary = this.state.summary
    const csrfToken = this.props.csrfToken

    let errorDetails = null

    if (failedCount > 0) {
      errorDetails = (
        <div>
          <div className='row mt-2'>
            <div className='col'>
              <h2>Errors</h2>
            </div>
          </div>
          <TransactionTable regime={regime}
            columns={columns}
            sortColumn={sortColumn}
            sortDirection={sortDirection}
            data={errorList.errors}
            onChangeSortDirection={this.toggleSortDirection}
            onChangeSortColumn={this.changeSortColumn}
          />
          <PaginationBar pagination={pagination}
            useMatchingLabel={false}
            pageSize={pageSize}
            currentPage={currentPage}
            onChangePageSize={this.changePageSize}
            onChangePage={this.changePage}
          />
        </div>
      )
    }

    return (
      <div>
        <DataFileSummary filename={filename}
          uploadDate={uploadDate}
          status={status}
          successCount={successCount}
          failedCount={failedCount}
        />
        { errorDetails }
      </div>
    )
  }
}
