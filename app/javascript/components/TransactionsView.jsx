import React from 'react'
import axios from 'axios'
import TransactionSummary from './TransactionSummary'
import TransactionTable from './TransactionTable'
import SearchBar from './SearchBar'
import PaginationBar from './PaginationBar'

export default class TransactionsView extends React.Component {
  constructor (props) {
    super(props)
    const transactions = this.props.transactions || this.emptyTransactions()
    this.state = {
      sortColumn: this.props.sortColumn,
      sortDirection: this.props.sortDirection,
      transactions: transactions,
      selectedRegion: this.props.selectedRegion,
      searchTerm: this.props.searchTerm,
      pageSize: transactions.pagination.per_page,
      currentPage: transactions.pagination.current_page
    }

    this.toggleSortDirection = this.toggleSortDirection.bind(this)
    this.changeSortColumn = this.changeSortColumn.bind(this)
    this.changeRegion = this.changeRegion.bind(this)
    this.search = this.search.bind(this)
    this.changePage = this.changePage.bind(this)
    this.changePageSize = this.changePageSize.bind(this)
    this.updateTransactionCategory = this.updateTransactionCategory.bind(this)
  }

  emptyTransactions () {
    const perPage = 10
    return {
      pagination: {
        per_page: perPage,
        current_page: 1
      },
      // NOTE: we need a polyfill for Array.prototype.fill on IE
      transactions: new Array(perPage).fill().map((_, i) => { return { id: i } })
    }
  }

  toggleSortDirection () {
    const direction = this.state.sortDirection === 'asc' ? 'desc' : 'asc'
    this.setState({sortDirection: direction, currentPage: 1}, () => {
      this.fetchTableData()
    })
  }

  changeSortColumn (columnName) {
    this.setState({sortColumn: columnName, sortDirection: 'asc', currentPage: 1}, () => {
      this.fetchTableData()
    })
  }

  changeRegion (region) {
    this.setState({selectedRegion: region, currentPage: 1}, () => {
      this.fetchTableData()
    })
  }

  search (term) {
    this.setState({searchTerm: term, currentPage: 1}, () => {
      this.fetchTableData()
    })
  }

  changePage (page) {
    this.setState({currentPage: page}, () => {
      this.fetchTableData()
    })
  }

  changePageSize (size) {
    this.setState({pageSize: size}, () => {
      this.fetchTableData()
    })
  }

  componentDidMount () {
    this.fetchTableData()
  }

  fetchTableData () {
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
        this.setState({
          transactions: res.data,
          pagination: res.data.pagination,
          pageSize: res.data.pagination.per_page,
          currentPage: res.data.pagination.current_page
        })
      })
      .catch(error => {
        // TODO: handle this
        console.log(error)
        throw error
      })
  }

  updateTransactionCategory (id, value) {
    axios.patch(this.props.path + '/' + id + '.json',
      {
        transaction_detail: {
          category: value
        }
      },
      {
        headers: {
          'X-CSRF-Token': this.props.csrfToken
        }
      })
    .then(res => {
      // update local data
      let data = this.state.transactions
      let idx = data.transactions.findIndex(t => {
        return t.id === id
      })
      if (idx !== -1) {
        data.transactions[idx] = res.data.transaction
        this.setState({ transactions: data })
      }
    })
    .catch(error => {
      console.log('error: ' + error)
    })
  }

  render () {
    const regime = this.props.regime
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
    if (typeof summary !== 'undefined' && summary !== null) {
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
