import React from 'react'
import SortableColumnHeader from './SortableColumnHeader'

export default class TransactionTableHeader extends React.Component {
  handleColumnClick (columnName, e) {
    e.preventDefault()
    if (this.isSelected(columnName)) {
      // toggle asc/desc flag
      this.props.onChangeSortDirection()
    } else {
      this.props.onChangeSortColumn(columnName)
    }
  }

  render () {
    const columns = this.props.columns
    const cols = columns.map((c) =>
      this.columnMarkup(c)
    )
    return (
      <thead>
        <tr>{cols}<td key='options' /></tr>
      </thead>
    )
  }

  columnMarkup (col) {
    if (col.name === 'excluded') {
      if (col.editable) {
        return <td key={col.name}/>
      } else {
        return ''
      }
    }
    
    if (col.sortable) {
      const selected = this.selectionInfo(col)
      return (
        <SortableColumnHeader
          key={col.name}
          column={col}
          selected={selected}
          clickHandler={this.handleColumnClick.bind(this, col.name)}
        />
      )
    } else {
      let title = null
      if (col.accessLabel) {
        title = (
          <span>
            <span aria-hidden='true'>{col.label}</span>
            <span className='sr-only'>{col.accessLabel}</span>
          </span>
        )
      } else {
        title = col.label
      }
      return (
        <th key={col.name} className={col.rightAlign === true ? 'text-right' : ''}>
          {title}
        </th>
      )
    }
  }

  isSelected (name) {
    return this.props.sortColumn === name
  }

  selectionInfo (col) {
    if (this.isSelected(col.name)) {
      return (
      {
        selected: true,
        direction: this.props.sortDirection
      })
    } else {
      return ({ selected: false })
    }
  }
}
