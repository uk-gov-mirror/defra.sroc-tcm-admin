import React from 'react'

export default class SortableColumnHeader extends React.Component {
  render () {
    const col = this.props.column
    const selected = this.props.selected

    let indicator = null
    let label = null

    if (selected.selected) {
      if (selected.direction === 'asc') {
        indicator = <span className='oi oi-caret-top' aria-hidden='true'></span>
        label = <span className='sr-only'> sorted in ascending order</span>
      } else {
        indicator = <span className='oi oi-caret-bottom' aria-hidden='true'></span>
        label = <span className='sr-only'> sorted in descending order</span>
      }
    }
    return (
      <th>
        <a href='#' onClick={this.props.clickHandler}>
          {col.label}{indicator}{label}
        </a>
      </th>
    )
  }
}
