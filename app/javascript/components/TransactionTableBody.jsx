import React from 'react'
import TransactionTableRow from './TransactionTableRow'

export default class TransactionTableBody extends React.Component {
  render () {
    const columns = this.props.columns
    const categories = this.props.categories
    const onChangeCategory = this.props.onChangeCategory

    const rows = this.props.data.map((r) =>
      <TransactionTableRow
        key={r.id}
        columns={columns}
        row={r}
        categories={categories}
        onChangeCategory={onChangeCategory}
      />)

    return (
      <tbody>
        { rows }
      </tbody>
    )
  }
}
