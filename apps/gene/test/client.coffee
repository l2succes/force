_ = require 'underscore'
benv = require 'benv'
Backbone = require 'backbone'
sinon = require 'sinon'
Gene = require '../../../models/gene'
{ resolve } = require 'path'
{ fabricate } = require 'antigravity'

describe 'GeneView', ->

  before (done) ->
    benv.setup =>
      benv.expose { $: benv.require 'jquery' }
      benv.render resolve(__dirname, '../templates/index.jade'), {
        sd: {}
        gene: new Gene fabricate 'gene'
      }
      Backbone.$ = $
      done()

  after ->
    benv.teardown()

  beforeEach ->
    { GeneView } = mod = benv.require resolve __dirname, '../client/index.coffee'
    mod.__set__ 'GeneFilter', class @GeneFilter
      initialize: ->
      reset: sinon.stub()
    mod.__set__ 'mediator', @mediator = { trigger: sinon.stub() }
    mod.__set__ 'ArtistFillwidthList', class @ArtistFillwidthList
      fetchAndRender: sinon.stub()
    sinon.stub Backbone, 'sync'
    @view = new GeneView el: $('body'), model: new Gene fabricate 'gene'

  afterEach ->
    Backbone.sync.restore()

  describe '#initialize', ->

    it 'sets up a share view', ->
      @view.shareButtons.$el.attr('id').should.equal 'gene-share-buttons'

    it 'does not setup artists if the gene is a subject matter gene', ->
      @view.renderArtistFillwidth = sinon.stub()
      @view.model.set type: { properties: [{ value: 'Subject Matter' }] }
      @view.initialize {}
      @view.renderArtistFillwidth.called.should.not.be.ok

    it 'inits a follow button view', ->
      @view.followButton.model.get('id').should.equal @view.model.get('id')

  describe '#setupArtistFillwidth', ->

    it 'inits a artist fillwidth view', ->
      @view.setupArtistFillwidth()
      Backbone.sync.args[0][2].success [fabricate 'artist', name: 'Andy Foobar']
      @ArtistFillwidthList::fetchAndRender.called.should.be.ok

describe 'GeneFilter', ->

  before (done) ->
    benv.setup =>
      benv.expose { $: benv.require 'jquery' }
      benv.render resolve(__dirname, '../templates/index.jade'), {
        sd: {}
        gene: new Gene fabricate 'gene'
      }
      Backbone.$ = $
      done()

  after ->
    benv.teardown()


  beforeEach ->
    GeneFilter = benv.require resolve(__dirname, '../client/filter.coffee')
    GeneFilter.__set__ 'ArtworkColumnsView', class @ArtworkColumnsView
      render: sinon.stub()
    GeneFilter.__set__ 'FilterArtworksNav', class @FilterArtworksNav
      render: sinon.stub()
    GeneFilter.__set__ 'FilterSortCount', class @FilterSortCount
      render: sinon.stub()
    GeneFilter.__set__ 'mediator', @mediator = {
      on: sinon.stub(),
      trigger: sinon.stub()
    }
    $.fn.infiniteScroll = sinon.stub()
    sinon.stub Backbone, 'sync'
    @view = new GeneFilter
      el: $('body')
      model: new Gene fabricate 'gene'

  afterEach ->
    Backbone.sync.restore()

  describe '#render', ->

    it 'renders the columns view', ->
      @view.render()
      @ArtworkColumnsView::render.called.should.be.ok

  describe '#nextPage', ->

    it 'fetches the next page of artworks', ->
      @view.$el.data 'state', 'artworks'
      @view.nextPage()
      Backbone.sync.args[0][1].url.should.include '/filtered/gene'
      Backbone.sync.args[0][2].data.page.should.equal @view.params.page

  describe '#reset', ->

    it 'sets the state to artwork mode', ->
      @view.reset()
      @view.$el.data('state').should.equal 'artworks'

    it 'fetches the filtered artworks', ->
      @view.reset { dimension: 24 }
      Backbone.sync.args[0][2].data.dimension.should.equal 24

    it 'fetches the filter suggest and triggers a counts update', ->
      @view.reset()
      _.last(Backbone.sync.args)[2].success { total: 1022 }
      @mediator.trigger.args[0][0].should.equal 'counts'
      @mediator.trigger.args[0][1].should.equal 'Showing 1022 Works'

  describe '#toggleArtistMode', ->

    it 'switches back to artist mode', ->
      @view.$el.attr 'data-state', 'artworks'
      @view.toggleArtistMode()
      @view.$el.attr('data-state').should.equal ''

  describe '#renderCounts', ->

    it 'renders the counts in the header', ->