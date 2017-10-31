import React from 'react'

export default class PageSizeSelector extends React.Component {
  constructor(props) {
    super(props)

    this.onChangeSize = this.onChangeSize.bind(this)
  }

  onChangeSize(ev) {
    this.props.onChangeSize(ev.target.value)
  }

  render() {
    const selectedPageSize = this.props.selectedPageSize
    const pageSizes = this.props.pageSizes
    const options = pageSizes.map((s) =>
      <option key={s} value={s}>{s}</option>
    )

    return (
      <div className='form-inline'>
        <label htmlFor='per_page' className='mr-sm-2'>Items per page</label>
        <select name='per_page' id='per_page' className='form-control'
          onChange={this.onChangeSize} value={selectedPageSize}>
          {options}
        </select>
      </div>
    )
  }
}
