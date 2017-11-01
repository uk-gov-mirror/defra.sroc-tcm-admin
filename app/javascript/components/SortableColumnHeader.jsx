import React from 'react'

export default class SortableColumnHeader extends React.Component {
  constructor(props) {
    super(props)
  }

  render() {
    const col = this.props.column
    const selected = this.props.selected

    let indicator = null

    if(selected.selected) {
      if(selected.direction === 'asc') {
        indicator = <span className="oi oi-caret-top"></span>
      } else {
        indicator = <span className="oi oi-caret-bottom"></span>
      }
    }
    return (
      <th><a href='#' onClick={this.props.clickHandler}>{col.label}{indicator}</a></th>
    )
  }
}
