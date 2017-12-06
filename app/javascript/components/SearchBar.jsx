import React from 'react'

export default class SearchBar extends React.Component {
  render () {
    return (
      <div className='row search-bar'>
        <div className='col mb-2 form-inline'>
          {this.props.children}
        </div>
      </div>
    )
  }
}
