import React from 'react'
import SelectionCell from './SelectionCell'

export default class TransactionTableRow extends React.Component {
  constructor(props) {
    super(props)
    this.onChangeCategory = this.onChangeCategory.bind(this)
  }

  onChangeCategory(value) {
    this.props.onChangeCategory(this.props.row.id, value)
  }

  buildCells() {
    const row = this.props.row
    const cells = this.props.columns.map((c) => {
      if(c.selectable) {
        const categories = this.props.categories
        return (
          <td key={c.name} className={c.rightAlign === true ? 'text-right' : ''}>
            <SelectionCell name={c.name} value={row[c.name]}
              options={categories} onChange={this.onChangeCategory} />
          </td>
        )
      } else {
        return (
          <td key={c.name} className={c.rightAlign === true ? 'text-right' : ''}>
            { row[c.name] }
          </td>
        )
      }
    })

    return cells
  }

  render() {
    const row = this.props.row

    return (
      <tr key={row.id}>
        { this.buildCells() }
      </tr>
    )
  }
}
