import React from 'react'
import TransactionTableHeader from './TransactionTableHeader'
import TransactionTableBody from './TransactionTableBody'

export default class TransactionTable extends React.Component {
  constructor(props) {
    super(props)
  }

  render() {
    const columns = this.props.columns
    const sortCol = this.props.sortColumn
    const sortDir = this.props.sortDirection
    const data = this.props.data
    const categories = this.props.categories
    const onSortColChange = this.props.onChangeSortColumn
    const onSortDirChange = this.props.onChangeSortDirection
    const onChangeCategory = this.props.onChangeCategory

    return (
      <table className="table table-responsive">
        <TransactionTableHeader columns={columns}
                                sortColumn={sortCol}
                                sortDirection={sortDir}
                                onChangeSortDirection={onSortDirChange}
                                onChangeSortColumn={onSortColChange}
        />
        <TransactionTableBody columns={columns} data={data}
                              categories={categories}
                              onChangeCategory={onChangeCategory}
        />
      </table>
    )
  }
}
