benv = require 'benv'
Backbone = require 'backbone'
sinon = require 'sinon'
CurrentUser = require '../../../../models/current_user.coffee'
Artworks = require '../../../../collections/artworks.coffee'
Partner = require '../../../../models/partner.coffee'
Profile = require '../../../../models/profile.coffee'
_ = require 'underscore'
{ resolve } = require 'path'
{ fabricate } = require 'antigravity'

describe 'PartnerView', ->

  before (done) ->
    benv.setup =>
      benv.expose { $: benv.require 'jquery' }
      Backbone.$ = $
      done()

  after ->
    benv.teardown()

  describe 'when setting up tabs', ->

    beforeEach (done) ->
      sinon.stub Backbone, 'sync'
      benv.render resolve(__dirname, '../../templates/index.jade'), {
        profile: new Profile fabricate 'partner_profile'
        sd: { PROFILE: fabricate 'partner_profile' }
        asset: (->)
        params: {}
      }, =>
        PartnerView = mod = benv.requireWithJadeify(
          resolve(__dirname, '../../client/view'), ['tablistTemplate']
        )
        @profile = new Profile fabricate 'partner_profile'
        @partner = @profile.related().owner
        mod.__set__ 'sectionToView', {}
        mod.__set__ 'tablistTemplate', (@tablistTemplate = sinon.stub())

        @view = new PartnerView
          profile: @profile
          partner: @partner
          el: $ 'body'
        done()

    afterEach ->
      Backbone.sync.restore()

    describe '#getDisplayableSections', ->
      describe 'with minimal data to display', ->
        beforeEach ->
          @partner.set {
            partner_artists_count: 0
            displayable_shows_count: 0
            published_not_for_sale_artworks_count: 0
            published_for_sale_artworks_count: 0
          }
        it 'gallery', ->
          @partner.set type: 'Gallery'
          @partner.set claimed: true
          @profile.set owner_type: 'PartnerGallery'
          sections = @view.getDisplayableSections @view.getSections()
          sections.should.eql ['overview', 'articles', 'contact']

        it 'institution', ->
          @partner.set type: 'Institution'
          @profile.set owner_type: 'PartnerInstitution'
          sections = @view.getDisplayableSections @view.getSections()
          sections.should.eql ['overview', 'articles', 'about']

      describe 'with maximum data to display', ->
        beforeEach ->
          @partner.set {
            partner_artists_count: 1
            displayable_shows_count: 1
            published_not_for_sale_artworks_count: 1
            published_for_sale_artworks_count: 1
          }

        describe 'gallery', ->
          beforeEach ->
            @partner.set type: 'Gallery'
            @partner.set claimed: true
            @profile.set owner_type: 'PartnerGallery'

          it 'returns proper sections when display works section is disabled', ->
            @partner.set display_works_section: false
            sections = @view.getDisplayableSections @view.getSections()
            sections.should.eql ['overview', 'shows', 'artists', 'articles', 'contact']

          it 'returns proper sections when display work section is enabled', ->
            @partner.set display_works_section: true
            sections = @view.getDisplayableSections @view.getSections()
            sections.should.eql ['overview', 'shows', 'works', 'artists', 'articles', 'contact']

        describe 'institution', ->
          beforeEach ->
            @partner.set type: 'Institution'
            @profile.set owner_type: 'PartnerInstitution'

          it 'returns proper sections when display works section is disabled', ->
            @partner.set display_works_section: false
            sections = @view.getDisplayableSections @view.getSections()
            sections.should.eql ['overview', 'shows', 'articles', 'shop', 'about']

          it 'returns proper sections when display work section is enabled', ->
            @partner.set display_works_section: true
            sections = @view.getDisplayableSections @view.getSections()
            sections.should.eql ['overview', 'shows', 'collection', 'articles', 'shop', 'about']

    describe '#initializeTablistAndContent', ->

      it 'renders tabs properly', ->
        @view.initializeTablistAndContent()
        _.last(@tablistTemplate.args)[0].profile.get('id').should.equal @profile.get('id')
        _.last(@tablistTemplate.args)[0].sections.should.eql ['overview', 'articles', 'about']