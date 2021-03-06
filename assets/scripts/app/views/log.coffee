require 'log'
require 'travis/lines_selector'
require 'travis/log_folder'

Log.DEBUG = false
Log.LIMIT = 10000

Travis.reopen
  LogView: Travis.View.extend
    templateName: 'jobs/log'
    logBinding: 'job.log'

    didInsertElement: ->
      @setupLog()

    logDidChange: (->
      @setupLog()
    ).observes('log')

    logWillChange: (->
      @teardownLog()
    ).observesBefore('log')

    willDestroyElement: ->
      @teardownLog()

    teardownLog: ->
      job = @get('job')
      job.unsubscribe() if job

    setupLog: ->
      job = @get('job')
      if job
        job.get('log').fetch()
        job.subscribe()

  PreView: Em.View.extend
    templateName: 'jobs/pre'

    logWillChange: (->
      console.log 'log view: log will change' if Log.DEBUG
      @teardownLog()
    ).observesBefore('log')

    didInsertElement: ->
      console.log 'log view: did insert' if Log.DEBUG
      @_super.apply this, arguments
      @createEngine()

    willDestroyElement: ->
      console.log 'log view: will destroy' if Log.DEBUG
      @teardownLog()

    versionDidChange: (->
      @rerender() if @get('_state') == 'inDOM'
    ).observes('log.version')

    logDidChange: (->
      console.log 'log view: log did change: rerender' if Log.DEBUG

      if @get('log')
        @createEngine()
        @rerender() if @get('_state') == 'inDOM'
    ).observes('log')

    teardownLog: ->
      if log = @get('log')
        parts = log.get('parts')
        parts.removeArrayObserver(@, didChange: 'partsDidChange', willChange: 'noop')
        parts.destroy()
        log.notifyPropertyChange('parts')
        @lineSelector?.willDestroy()

    createEngine: ->
      if @get('log')
        console.log 'log view: create engine' if Log.DEBUG
        @scroll = new Log.Scroll beforeScroll: =>
          @unfoldHighlight()
        @engine = Log.create(limit: Log.LIMIT, listeners: [@scroll])
        @logFolder = new Travis.LogFolder(@$().find('#log'))
        @lineSelector = new Travis.LinesSelector(@$().find('#log'), @scroll, @logFolder)
        @observeParts()

    unfoldHighlight: ->
      @lineSelector.unfoldLines()

    observeParts: ->
      if log = @get('log')
        parts = log.get('parts')
        parts.addArrayObserver(@, didChange: 'partsDidChange', willChange: 'noop')
        parts = parts.slice(0)
        @partsDidChange(parts, 0, null, parts.length)

    partsDidChange: (parts, start, _, added) ->
      console.log 'log view: parts did change' if Log.DEBUG
      for part, i in parts.slice(start, start + added)
        # console.log "limit in log view: #{@get('limited')}"
        break if @get('limited')
        @engine.set(part.number, part.content)
        @propertyDidChange('limited')

    limited: (->
      @engine?.limit?.limited
    ).property()

    plainTextLogUrl: (->
      if id = @get('log.job.id')
        url = Travis.Urls.plainTextLog(id)
        if Travis.config.pro
          url += "&access_token=#{@get('job.log.token')}"
        url
    ).property('job.log.id', 'job.log.token')

    actions:
      toTop: () ->
        $(window).scrollTop(0)

      toggleTailing: ->
        Travis.tailing.toggle()
        @engine.autoCloseFold = !Travis.tailing.isActive()
        event.preventDefault()

    noop: -> # TODO required?

Log.Scroll = (options) ->
  options ||= {}
  @beforeScroll = options.beforeScroll
  this
Log.Scroll.prototype = $.extend new Log.Listener,
  insert: (log, data, pos) ->
    @tryScroll() if @numbers
    true

  tryScroll: ->
    if element = $("#log p:visible.highlight:first")
      if @beforeScroll
        @beforeScroll()
      $('#main').scrollTop(0)
      $('html, body').scrollTop(element.offset()?.top - (window.innerHeight / 3)) # weird, html works in chrome, body in firefox

# Log.Logger = ->
# Log.Logger.prototype = $.extend new Log.Listener,
#   receive: (log, num, string) ->
#     @log("rcv #{num} #{JSON.stringify(string)}")
#     true
#   insert: (log, element, pos) ->
#     @log("ins #{element.id}, #{if pos.before then 'before' else 'after'}: #{pos.before || pos.after || '?'}, #{JSON.stringify(element)}")
#   remove: (log, element) ->
#     @log("rem #{element.id}")
#   log: (line) ->
#     console.log(line)
