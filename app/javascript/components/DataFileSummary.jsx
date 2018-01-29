import React from 'react'

export default class DataFileSummary extends React.Component {
  render () {
    const filename = this.props.filename
    const uploadDate = this.props.uploadDate
    const status = this.props.status
    const successCount = this.props.successCount
    const failedCount = this.props.failedCount

    return (
      <div className='panel'>
        <dl className='row'>
          <dt className='col-sm-4 col-md-3'>Filename</dt>
          <dd className='col-sm-7 col-md-8'>{ filename }</dd>
          <dt className='col-sm-4 col-md-3'>Date uploaded</dt>
          <dd className='col-sm-7 col-md-8'>{ uploadDate }</dd>
          <dt className='col-sm-4 col-md-3'>Status</dt>
          <dd className='col-sm-7 col-md-8'>{ status }</dd>
          <dt className='col-sm-4 col-md-3'>Records updated</dt>
          <dd className='col-sm-7 col-md-8'>{ successCount }</dd>
          <dt className='col-sm-4 col-md-3'>Errors detected</dt>
          <dd className='col-sm-7 col-md-8'>{ failedCount }</dd>
        </dl>
      </div>
    )
  }
}
