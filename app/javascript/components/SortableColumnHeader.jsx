import React from 'react'

export default class SortableColumnHeader extends React.Component {
  render () {
    const col = this.props.column
    const selected = this.props.selected

    let indicator = null

    if (selected.selected) {
      if (selected.direction === 'asc') {
        indicator = <span className='oi oi-caret-top' />
      } else {
        indicator = <span className='oi oi-caret-bottom' />
      }
    }
    return (
      <th><a href='#' onClick={this.props.clickHandler}>{col.label}{indicator}</a></th>
    )
  }
}
