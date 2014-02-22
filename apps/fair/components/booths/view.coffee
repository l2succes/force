_                       = require 'underscore'
Backbone                = require 'backbone'
sd                      = require('sharify').data
FeedItems               = require '../../../../components/feed/collections/feed_items.coffee'
FeedView                = require '../../../../components/feed/client/feed.coffee'
BorderedPulldown        = require '../../../../components/bordered_pulldown/view.coffee'
qs                      = require 'querystring'
FilterNav               = require '../../../../components/filter/nav/view.coffee'
navSectionsTemplate     = -> require('./nav_sections.jade') arguments...

module.exports = class BoothsView extends Backbone.View

  sortOrder: "-featured"

  initialize: (options) ->
    _.extend @, options

    # Set up a @params model to maintain the query param state for the @shows collection
    # attched to /api/v1/fair/:id/shows
    @params = new Backbone.Model(artworks: true, size: 3)
    @shows = new FeedItems
    @shows.url = "#{@fair.url()}/shows"

    # Add child view
    new BorderedPulldown
      el: @$('#fair-booths-sort .bordered-pulldown')
    new FilterNav
      el: @$('#fair-booths-filter-nav')
      params: @params
      highlightAllAttrs: ['section']

    # Hook into param changes to update view/router state
    @params.on 'change', @renderHeader
    @params.on 'change', @fetchShows
    @params.on 'change:section', @navigateSection
    @params.on 'change:sort', @navigateSort
    @shows.on 'request', @toggleSpinner
    @shows.on 'sync', @toggleSpinner
    @shows.on 'sync', @renderShows

    # Render the navigation dropdown sections
    @fair.fetchSections success: @renderSections

  toggleSpinner: =>
    @$('.browse-section.booths .feed, #fair-booths-spinner').toggle()

  renderSections: (sections) =>
    hash = {}
    sections.each (section) -> hash[section.get 'section'] = section.get('section')
    @$('#fair-filter-sections').html navSectionsTemplate(sections: hash)

  fetchShows: =>
    @shows.fetch data: @params.toJSON()

  renderHeader: =>
    @$('.browse-section.booths h1').text if @params.get 'section'
                    "Exhibitors at #{@params.get 'section'}"
                  else if @params.get 'partner_region'
                    "Exhibitors from #{@params.get 'partner_region'}"
                  else
                    'All Exhibitors'

  renderShows: (items) =>
    return @$('.#fair-browse-spinner') unless items.models.length > 0
    items.urlRoot = @shows.url
    @feedView?.destroy()
    @feedView?.remove()
    @feedView = new FeedView
     el: $el = $('<div>')
     feedItems: items
     additionalParams: @params.toJSON()
    @$('.browse-section.booths .feed').html @feedView.$el
    @$('#fair-browse-spinner').show()

  navigateSection: =>
    if @params.get 'section'
      @router.navigate "#{@profile.id}/browse/booths/section/#{@params.get 'section'}"
    else
      @router.navigate "#{@profile.id}/browse/booths"

  navigateSort: =>
    @router.navigate location.pathname + "?sort=#{@params.get 'sort'}"

  events:
    'click #fair-booths-sort a'         : 'sort'
    'click #fair-filter-all-exhibitors' : 'allExhibitors'

  sort: (e) ->
    @params.set sort: $(e.target).data 'sort'
