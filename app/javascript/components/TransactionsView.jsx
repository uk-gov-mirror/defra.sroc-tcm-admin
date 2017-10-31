import React from 'react'
import ReactDOM from 'react-dom'
import axios from 'axios'
import TransactionSummary from './TransactionSummary'
import TransactionTable from './TransactionTable'
import SearchBar from './SearchBar'
import PaginationBar from './PaginationBar'

export default class TransactionsView extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      sortColumn: this.props.sortColumn,
      sortDirection: this.props.sortDirection,
      transactions: this.props.transactions,
      selectedRegion: this.props.selectedRegion,
      searchTerm: this.props.searchTerm,
      pageSize: this.props.transactions.pagination.per_page,
      currentPage: this.props.transactions.pagination.current_page
    }

    this.toggleSortDirection = this.toggleSortDirection.bind(this)
    this.changeSortColumn = this.changeSortColumn.bind(this)
    this.changeRegion = this.changeRegion.bind(this)
    this.search = this.search.bind(this)
    this.changePage = this.changePage.bind(this)
    this.changePageSize = this.changePageSize.bind(this)
    this.updateTransactionCategory = this.updateTransactionCategory.bind(this)
  }

  toggleSortDirection() {
    const direction = this.state.sortDirection === 'asc' ? 'desc' : 'asc'
    console.log('sort direction changed - go query for new stuff')
    this.setState({sortDirection: direction, currentPage: 1}, () => {
      this.fetchTableData()
    })
  }

  changeSortColumn(columnName) {
    console.log('sort column changed - go query for new stuff')
    this.setState({sortColumn: columnName, sortDirection: 'asc', currentPage: 1}, () => {
      this.fetchTableData()
    })
  }

  changeRegion(region) {
    console.log('change region to ' + region)
    this.setState({selectedRegion: region, currentPage: 1}, () => {
      this.fetchTableData()
    })
  }

  search(term) {
    console.log('search for ' + term)
    this.setState({searchTerm: term, currentPage: 1}, () => {
      this.fetchTableData()
    })
  }

  changePage(page) {
    console.log('page changed to: ' + page)
    this.setState({currentPage: page}, () => {
      this.fetchTableData()
    })
  }

  changePageSize(size) {
    console.log('page size changed to: ' + size)
    this.setState({pageSize: size}, () => {
      this.fetchTableData()
    })
  }

  fetchTableData() {
    axios.get(this.props.path + '.json', {
      params: {
        sort: this.state.sortColumn,
        sort_direction: this.state.sortDirection,
        region: this.state.selectedRegion,
        search: this.state.searchTerm,
        page: this.state.currentPage,
        per_page: this.state.pageSize
      }
    })
      .then(res => {
        this.setState({ transactions: res.data,
                        pagination: res.data.pagination,
                        pageSize: res.data.pagination.per_page,
                        currentPage: res.data.pagination.current_page
                       })
      })
  }

  updateTransactionCategory(id, value) {
    console.log('transaction category change: ' + id + ' value: ' + value)
    axios.patch(this.props.path + '/' + id + '.json', {
        transaction_detail: {
          category: value
        }
      },
      {
      headers: {
        'X-CSRF-Token': this.props.csrfToken
      }
    })
  }

  render() {
    const regime = this.props.regime
    const mode = this.props.mode
    const columns = this.props.columns
    const sortColumn = this.state.sortColumn
    const sortDirection = this.state.sortDirection
    const transactions = this.state.transactions.transactions
    const pagination = this.state.transactions.pagination
    const regions = this.props.regions
    const selectedRegion = this.state.selectedRegion
    const searchTerm = this.state.seachTerm
    const searchPlaceholder = this.props.searchPlaceholder
    const currentPage = this.state.currentPage
    const pageSize = this.state.pageSize
    const summary = this.state.transactions.summary
    const categories = this.props.categories

    let transactionSummary = null
    if(typeof summary !== 'undefined' && summary !== null) {
      transactionSummary = (
        <TransactionSummary summary={summary} />
      )
    }

    return (
      <div>
        { transactionSummary }
        <SearchBar regions={regions}
          selectedRegion={selectedRegion}
          onChangeRegion={this.changeRegion}
          searchPlaceholder={searchPlaceholder}
          searchTerm={searchTerm}
          onSearch={this.search}
        />
        <TransactionTable regime={regime}
          mode={mode}
          columns={columns}
          sortColumn={sortColumn}
          sortDirection={sortDirection}
          data={transactions}
          categories={categories}
          onChangeSortDirection={this.toggleSortDirection}
          onChangeSortColumn={this.changeSortColumn}
          onChangeCategory={this.updateTransactionCategory}
        />
        <PaginationBar pagination={pagination}
          pageSize={pageSize}
          currentPage={currentPage}
          onChangePageSize={this.changePageSize}
          onChangePage={this.changePage}
        />
      </div>
    )
  }
}

const loadEvent = (typeof Turbolinks !== 'undefined') ? 'turbolinks:load' : 'DOMContentLoaded'
document.addEventListener(loadEvent, () => {
  const element = document.getElementById('transaction-table')
  const regime = element.getAttribute('data-regime')
  const mode = element.getAttribute('data-mode') || 'ttbb'
  const showSummary = element.getAttribute('data-with-summary') === 'true'
  const sortColumn = element.getAttribute('data-sort-col')
  const sortDir = element.getAttribute('data-sort-dir')
  const columns = JSON.parse(element.getAttribute('data-columns'))
  const path = element.getAttribute('data-path')
  const transactions = JSON.parse(element.getAttribute('data-transactions'))
  const regions = JSON.parse(element.getAttribute('data-regions'))
  const selectedRegion = element.getAttribute('data-selected-region')
  const searchPlaceholder = element.getAttribute('data-search-placeholder')
  const searchTerm = element.getAttribute('data-search-term')
  const categories = JSON.parse(element.getAttribute('data-categories'))
  const csrfToken = document.querySelector('meta[name=csrf-token]').content

  ReactDOM.render(
    <TransactionsView regime={regime} mode={mode} columns={columns}
                  showSummary={showSummary}
                  sortColumn={sortColumn} sortDirection={sortDir}
                  categories={categories}
                  path={path}
                  csrfToken={csrfToken}
                  transactions={transactions}
                  regions={regions}
                  selectedRegion={selectedRegion}
                  searchTerm={searchTerm} searchPlaceholder={searchPlaceholder} />,
    element
  )
})
