import React from 'react'
import SortableColumnHeader from './SortableColumnHeader'

export default class TransactionTableHeader extends React.Component {
  constructor(props) {
    super(props)
    // this.handleColumnClick = this.handleColumnClick.bind(this)
  }

  handleColumnClick(columnName, e) {
    e.preventDefault()
    if(this.isSelected(columnName)) {
      // toggle asc/desc flag
      console.log('toggle ' + columnName)
      this.props.onChangeSortDirection()
    } else {
      console.log('switch sort column to ' + columnName)
      this.props.onChangeSortColumn(columnName)
    }
  }

  render() {
    const columns = this.props.columns
    const cols = columns.map((c) =>
      this.columnMarkup(c)
    )
    return (
      <thead>
        <tr>{cols}<td /></tr>
      </thead>
    )
  }

  columnMarkup(col) {
    if(col.sortable) {
      const selected = this.selectionInfo(col)
      return (
        <SortableColumnHeader key={col.name} column={col} selected={selected} clickHandler={this.handleColumnClick.bind(this, col.name)} />
      )
    } else {
      return (
        <th key={col.name} className={col.rightAlign === true ? 'text-right' : ''}>
          {col.label}
        </th>
      )
    }
  }

  isSelected(name) {
    return this.props.sortColumn === name
  }

  selectionInfo(col) {
    if(this.isSelected(col.name)) {
      return (
        {
          selected: true,
          direction: this.props.sortDirection
        }
      )
    } else {
      return ({ selected: false })
    }
  }
}
