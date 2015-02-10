_ = require 'underscore'
benv = require 'benv'
sinon = require 'sinon'
Backbone = require 'backbone'
{ fabricate } = require 'antigravity'
Artist = require '../../../../models/artist.coffee'
CurrentUser = require '../../../../models/current_user.coffee'

describe 'ArtistRouter', ->
  before (done) ->
    benv.setup =>
      benv.expose $: benv.require 'jquery'
      Backbone.$ = $
      @ArtistRouter = require '../../client/router'
      done()

  after ->
    benv.teardown()

  beforeEach ->
    sinon.stub Backbone, 'sync'
    sinon.stub @ArtistRouter::, 'navigate'
    @model = new Artist fabricate 'artist', id: 'foo-bar'
    @user = new CurrentUser fabricate 'user'
    @router = new @ArtistRouter model: @model, user: @user

  afterEach ->
    Backbone.sync.restore()
    @router.navigate.restore()

  describe '#execute', ->
    beforeEach ->
      @renderStub = renderStub = sinon.stub()
      class @StubbedView extends Backbone.View
        render: -> renderStub(); this
      @router.view = new @StubbedView
      @router.headerView = new @StubbedView

    it 'returns if a view is already rendered', ->
      @router.execute()
      @renderStub.called.should.be.false
