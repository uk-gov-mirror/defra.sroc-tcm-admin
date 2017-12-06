/* eslint no-console:0 */
import 'babel-polyfill'
import React from 'react'
import ReactDOM from 'react-dom'
import TransactionsView from '../components/TransactionsView'
import Constants from '../components/constants'

const loadEvent = (typeof Turbolinks !== 'undefined') ? 'turbolinks:load' : 'DOMContentLoaded'
document.addEventListener(loadEvent, () => {
  const element = document.getElementById('transaction-table')
  const regime = element.getAttribute('data-regime')
  const historic = element.getAttribute('data-historic') === 'true'
  const showSummary = element.getAttribute('data-with-summary') === 'true'
  const sortColumn = element.getAttribute('data-sort-col')
  const sortDir = element.getAttribute('data-sort-dir')
  const columns = Constants.regimeColumns(regime, historic)
  // const columns = JSON.parse(element.getAttribute('data-columns'))
  const path = element.getAttribute('data-path')
  const summaryPath = element.getAttribute('data-summary-path')
  const generateFilePath = element.getAttribute('data-generate-file-path')
  // const transactions = JSON.parse(element.getAttribute('data-transactions'))
  const regions = JSON.parse(element.getAttribute('data-regions'))
  const selectedRegion = element.getAttribute('data-selected-region')
  const searchPlaceholder = element.getAttribute('data-search-placeholder')
  const searchTerm = element.getAttribute('data-search-term')
  const categories = JSON.parse(element.getAttribute('data-categories'))
  const csrfToken = document.querySelector('meta[name=csrf-token]').content
  const generateFiles = element.getAttribute('data-generate-files') === 'true'

  ReactDOM.render(
    <TransactionsView
      regime={regime}
      historic={historic}
      columns={columns}
      showSummary={showSummary}
      sortColumn={sortColumn} sortDirection={sortDir}
      categories={categories}
      path={path}
      summaryPath={summaryPath}
      csrfToken={csrfToken}
      regions={regions}
      selectedRegion={selectedRegion}
      searchTerm={searchTerm} searchPlaceholder={searchPlaceholder}
      generateFiles={generateFiles}
      generateFilePath={generateFilePath}
    />,
    element
  )
})
