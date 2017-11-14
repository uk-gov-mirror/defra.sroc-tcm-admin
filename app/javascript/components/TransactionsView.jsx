import React from 'react'
import axios from 'axios'
import Constants from './constants'
import TransactionSummary from './TransactionSummary'
import TransactionTable from './TransactionTable'
import SearchBar from './SearchBar'
import PaginationBar from './PaginationBar'

export default class TransactionsView extends React.Component {
  constructor(props) {
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

  emptyTransactions() {
    return {
      pagination: {
        per_page: 10,
        current_page: 1},
      transactions: [],
      summary: {}
    }
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

  componentDidMount() {
    this.fetchTableData()
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
      .catch(error => {
        // TODO: handle this
        console.log(error)
        throw error
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
    .then(res => {
      console.log(res.data)
      // update local data
      let data = this.state.transactions
      let idx = data.transactions.findIndex(t => {
        return t.id === id
      })
      if(idx !== -1) {
        data.transactions[idx] = res.data.transaction
        this.setState({ transactions: data })
      }
    })
    .catch(error => {
      console.log("error: " + error)
    })
  }

  render() {
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
