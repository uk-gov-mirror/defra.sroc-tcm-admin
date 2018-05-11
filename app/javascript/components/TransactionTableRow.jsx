import React from 'react'
import SelectionCell from './SelectionCell'
import OptionSelector from './OptionSelector'
import ErrorPopup from './ErrorPopup'

export default class TransactionTableRow extends React.Component {
  constructor (props) {
    super(props)
    this.state = {
      excluded: !!this.props.row.excluded
    }
    this.onChangeCategory = this.onChangeCategory.bind(this)
    this.onChangeTemporaryCessation = this.onChangeTemporaryCessation.bind(this)
    this.toggleExcluded = this.toggleExcluded.bind(this)
    this.onExclusionSave = this.onExclusionSave.bind(this)
    this.onExclusionCancel = this.onExclusionCancel.bind(this)
  }

  onChangeCategory (value) {
    this.props.onChangeCategory(this.props.row.id, value)
  }

  onChangeTemporaryCessation (value) {
    this.props.onChangeTemporaryCessation(this.props.row.id, value)
  }

  mapYN (value) {
    return (value === 'Y' || value === 'y') ? '1' : '0'
  }

  toggleExcluded (ev) {
    const excluded = this.state.excluded

    if (excluded) {
      this.props.onReinstateTransaction(this.props.row.id)
      console.log("Reinstate " + this.props.row.id)
    } else {
      console.log("Exclude " + this.props.row.id)
      this.props.onShowExclusionDialog(this.onExclusionSave, this.onExclusionCancel)
    }

    this.setState({
      excluded: !excluded
    })
  }

  onExclusionSave (reason) {
    console.log('onExclusionSave ' + reason)
    this.props.onExcludeTransaction(this.props.row.id, reason)
  }

  onExclusionCancel () {
    console.log('cancel callback')
    this.setState({
      excluded: false
    })
  }

  accessHelpText(col, row) {
    let helpTxt = null
    if (col.accessHelp) {
      helpTxt = col.accessHelp + row[col.accessHelpColumn]
    }
    return helpTxt
  }

  excludeOrReinstate(col, row) {
    return row[col.name] ? 'Reinstate' : 'Exclude'
  }

  excludedHelpText(col, row) {
    return this.excludeOrReinstate(col, row) + ' ' + this.accessHelpText(col, row)
  }

  buildCells () {
    const row = this.props.row
    const ynOptions = [
      {
        label: 'Y',
        value: '1'
      },
      { label: 'N',
        value: '0'
      }
    ]

    const excluded = this.state.excluded
    let cells = this.props.columns.map((c) => {
      const clz = 'align-middle' + (c.rightAlign === true ? ' text-right' : '')
      if (c.editable && (!excluded || c.name === 'excluded')) {
        if (c.name === 'sroc_category') {
          const categories = this.props.categories
          const catId = 'category-' + row['id']
          const helpTxt = this.accessHelpText(c, row)

          return (
            <td key={c.name} className={clz}>
              <label htmlFor={catId} className='sr-only'>
                {helpTxt}
              </label>
              <SelectionCell
                id={catId}
                name={c.name}
                value={row[c.name]}
                options={categories}
                onChange={this.onChangeCategory}
              />
            </td>
          )
        } else if (c.name === 'temporary_cessation') {
          const tcId = 'tc-' + row['id']
          const helpTxt = this.accessHelpText(c, row)

          return (
            <td key={c.name} className={clz}>
              <label htmlFor={tcId} className='sr-only'>
                {helpTxt}
              </label>
              <OptionSelector
                id={tcId}
                className='form-control'
                selectedValue={this.mapYN(row[c.name])}
                options={ynOptions}
                name={c.name}
                onChange={this.onChangeTemporaryCessation}
              />
            </td>
          )
        } else if (c.name === 'excluded') {
          const exId = 'ex-' + row['id']
          const exHelpTxt = this.excludedHelpText(c, row)

          return (
            <td key={c.name}>
                <label htmlFor={exId} className='sr-only'>
                  {exHelpTxt}
                </label>
                <input
                  type='checkbox'
                  id={exId}
                  className='form-check-input exclude-button'
                  name={c.name}
                  title={this.excludeOrReinstate(c, row)}
                  checked={excluded}
                  onChange={this.toggleExcluded}
                />
            </td>
          )
        } else {
          return ( <td key={c.name}>Unknown editable</td>)
        }
      } else {
        return (
          <td key={c.name} className={clz}>
            { row[c.name] }
          </td>
        )
      }
    })
      
    if (row.error_message) {
      cells.push(
        <td key='error' className='error-popup align-middle'>
          <ErrorPopup message={row.error_message} open={false} />
        </td>
      )
    }

    return cells
  }

  render () {
    const row = this.props.row
    let clz = '';
    if (row.error_message) {
      clz = 'alert-danger '
    }
    if (row.excluded) {
      clz = clz + 'excluded'
    }
    return (
      <tr key={row.id} className={clz}>
        { this.buildCells() }
      </tr>
    )
  }
}
