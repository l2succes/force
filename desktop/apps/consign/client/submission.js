import React from 'react'
import { BrowserRouter } from 'react-router-dom'
import geo from '../../../components/geo/index.coffee'
import reducers from './reducers'
import createHistory from 'history/createBrowserHistory'
import createLogger from 'redux-logger'
import thunkMiddleware from 'redux-thunk'
import { createStore, applyMiddleware } from 'redux'
import { render } from 'react-dom'
import { routerMiddleware } from 'react-router-redux'
import App from '../components/app'
import analyticsMiddleware from './analytics_middleware'

function setupSubmissionFlow () {
  // load google maps for autocomplete
  geo.loadGoogleMaps()
  const history = createHistory()

  // track pageviews when react-router updates the url
  history.listen((ev) => {
    window.analytics.page(
      { path: ev.pathname },
      { integrations: { 'Marketo': false } }
    )
  })

  const middleware = []

  middleware.push(thunkMiddleware) // lets us dispatch() functions
  middleware.push(routerMiddleware(history))
  middleware.push(analyticsMiddleware) // middleware to help us track previous and future states

  if (sd.NODE_ENV === 'development' || sd.NODE_ENV === 'staging') {
    middleware.push(createLogger({ // middleware that logs actions
      collapsed: true
    }))
  }

  const store = createStore(
    reducers,
    applyMiddleware(...middleware)
  )

  render((
    <BrowserRouter>
      <App store={store} />
    </BrowserRouter>
  ),
  document.getElementById('consignments-submission__flow')
  )
}

export default () => {
  setupSubmissionFlow()
}
