import React from 'react'

export default class PaginationInfo extends React.Component {
  constructor(props) {
    super(props)
  }

  zero() {
    return (
      <span>No records found</span>
    )
  }

  one() {
    return (
      <span>Displaying <b>1</b> matching record</span>
    )
  }

  all(count) {
    return (
      <span>Displaying <b>all {count}</b> matching records</span>
    )
  }

  entries(start, end, total) {
    return (
      <span>Displaying <b>{start} - {end}</b> of <b>{total}</b> matching entries</span>
    )
  }

  render() {
    const pagination = this.props.pagination
    const currentPage = pagination.current_page
    const perPage = pagination.per_page
    const total = pagination.total_count
    const start = ((currentPage - 1) * perPage) + 1
    const rangeEnd = Math.min(start + perPage - 1, total)
    let message = null
    
    if(total === 0) {
      message = this.zero()
    } else if(total === 1) {
      message = this.one()
    } else if(total <= perPage) {
      message = this.all(total)
    } else {
      message = this.entries(start, rangeEnd, total)
    }

    return (
      <div className='page-info'>
        { message }
      </div>
    )
  }
}
