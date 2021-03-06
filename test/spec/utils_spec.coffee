define [
  'backbone'
  'underscore'
  'chaplin/lib/utils'
  'chaplin/mediator'
], (Backbone, _, utils, mediator) ->
  'use strict'

  describe 'utils', ->
    class A
      prop: 1
    class B extends A
      prop: null
    class C extends B
      prop: 2
    class D extends C
      prop: 3

    describe 'isEmpty', ->
      it 'should check whether an object does not have own properties', ->
        obj = {}
        expect(utils.isEmpty(obj)).to.equal true
        obj.a = 1
        expect(utils.isEmpty(obj)).to.equal false

      it 'should check only own properties', ->
        obj = Object.create {b:2}
        expect(utils.isEmpty(obj)).to.equal true

      it 'should check non-enumerable properties too', ->
        obj = {}
        Object.defineProperty obj, 'c', {value:3}
        expect(utils.isEmpty(obj)).to.equal false

    describe 'serialize', ->
      it 'should serialize objects and incorporate duck-typing', ->
        model = new Backbone.Model a: 1
        expect(utils.serialize model).to.eql a: 1
        expect(utils.serialize {serialize: -> 5}).to.be 5
        expect(-> utils.serialize {}).to.throwError()

    describe 'readonly', ->
      it 'should make property read-only', ->
        strict = do (-> 'use strict'; !this)
        object = {a: 228}
        supports = utils.readonly object, 'a'
        expect(-> object.a = 666).to.throwError() if supports and strict

    describe 'getPrototypeChain', ->
      it 'should get prototype chain of instance', ->
        object = new D
        expect(utils.getPrototypeChain object).to.eql [
          Object.prototype,
          A.prototype,
          B.prototype,
          C.prototype,
          D.prototype
        ]

    describe 'getAllPropertyVersions', ->
      it 'should get property from all prototypes', ->
        object = new D
        expect(utils.getAllPropertyVersions object, 'prop').to.eql [1, 2, 3]

    describe 'upcase', ->
      it 'should make the first character in string upper-cased', ->
        expect(utils.upcase 'stuff').to.be 'Stuff'
        expect(utils.upcase 'стафф').to.be 'Стафф'
        expect(utils.upcase '123456').to.be '123456'

    describe 'reverse', ->
      beforeEach ->
        mediator.unsubscribe()
      afterEach ->
        mediator.unsubscribe()

      it 'should return the url for a named route', ->
        stubbedRouteHandler = (routeName, params) ->
          expect(routeName).to.be 'foo'
          expect(params).to.eql {id: 3, d: "data"}
          '/foo/bar'
        mediator.setHandler 'router:reverse', stubbedRouteHandler

        url = utils.reverse 'foo', id: 3, d: "data"
        expect(url).to.be '/foo/bar'

      it 'should return the url for a named route with empty path', ->
        stubbedRouteHandler = (routeName, params) ->
          expect(routeName).to.be 'home'
          expect(params).to.be undefined
          '/'
        mediator.setHandler 'router:reverse', stubbedRouteHandler

        url = utils.reverse 'home'
        expect(url).to.be '/'

      it 'should throw exception if no route found', ->
        stubbedRouteHandler = (routeName, params) ->
          false
        mediator.setHandler 'router:reverse', stubbedRouteHandler

        try
          url = utils.reverse 'foo', id: 3, d: "data"
        catch err
          expect(err).to.be.an Error

      # it 'should return null if router does not respond', ->
      #   url = utils.reverse 'foo', id: 3, d: "data"
      #   expect(url).to.be null

    describe 'queryParams', ->
      queryParams = p1: 'With space', p2_empty: '', 'p 3': [999, 'a&b']
      queryString = 'p1=With%20space&p2_empty=&p%203=999&p%203=a%26b'

      it 'should serialize query parameters from object into string', ->
        expect(utils.querystring.stringify queryParams).to.be queryString

      it 'should ignore undefined and null values when serializing query parameters', ->
        queryParams1 = p1: null, p2: undefined, p3: 'third'
        expect(utils.querystring.stringify queryParams1).to.be 'p3=third'

      it 'should deserialize query parameters from query string into object', ->
        expect(utils.querystring.parse queryString).to.eql queryParams

      it 'should take a full url and only return params object', ->
        expect(utils.querystring.parse "http://foo.com/app/path?#{queryString}").to.eql queryParams

      it 'should have old methods', ->
        expect(utils.queryParams.stringify).to.be.a 'function'
        expect(utils.queryParams.parse).to.be.a 'function'
