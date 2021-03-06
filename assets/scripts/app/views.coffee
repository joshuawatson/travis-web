require 'ext/ember/namespace'

Em.View.reopen
  init: ->
    this.container ||= Travis.__container__

    @_super.apply(this, arguments)

Travis.NotFoundView = Ember.View.extend
  layoutName: 'layouts/simple'

@Travis.reopen
  View: Em.View.extend
    actions:
      popup: (name) -> @popup(name)
      popupClose: -> @popupClose()

    popup: (name) ->
      @popupCloseAll()
      name = event?.target?.name || name
      $("##{name}").toggleClass('display')
    popupClose: ->
      $('.popup').removeClass('display')
    popupCloseAll: ->
      if view = Travis.View.currentPopupView
        view.destroy()
        Travis.View.currentPopupView = null

      $('.popup').removeClass('display')

Travis.MainView = Travis.View.extend
  layoutName: 'layouts/home'
  classNames: ['application']

@Travis.NoOwnedReposView = Ember.View.extend
  templateName: 'pro/no_owned_repos'

Travis.GettingStartedView = Travis.View.extend
  templateName: (->
    if Travis.config.pro
      'pro/no_owned_repos'
    else
      'no_owned_repos'
  ).property()

Travis.AuthSigninView = Travis.View.extend
  layoutName: 'layouts/simple'

Travis.InsufficientOauthPermissionsView = Travis.View.extend
  layoutName: 'layouts/simple'
  classNames: ['application']

Travis.FirstSyncView = Travis.View.extend
  layoutName: 'layouts/simple'
  classNames: ['application']
  didInsertElement: ->
    this.addObserver('controller.isSyncing', this, this.isSyncingDidChange)

  willDestroyElement: ->
    this.removeObserver('controller.isSyncing', this, this.isSyncingDidChange)

  isSyncingDidChange: ->
    if !@get('controller.isSyncing')
      self = this
      Ember.run.later this, ->
        Travis.Repo.fetch(member: @get('controller.user.login')).then( (repos) ->
          if repos.get('length')
            self.get('controller').transitionToRoute('index')
          else
            self.get('controller').transitionToRoute('profile')
        ).then(null, (e) ->
          console.log('There was a problem while redirecting from first sync', e)
        )
      , Travis.config.syncingPageRedirectionTime


Travis.SidebarView = Travis.View.extend
  templateName: 'layouts/sidebar'

  didInsertElement: ->
    @_super.apply this, arguments

  classQueues: (->
    'active' if @get('activeTab') == 'queues'
  ).property('activeTab')

  classWorkers: (->
    'active' if @get('activeTab') == 'workers'
  ).property('activeTab')

  classJobs: (->
    'active' if @get('activeTab') == 'jobs'
  ).property('activeTab')

Travis.QueueItemView = Travis.View.extend
  tagName: 'li'

Travis.RunningJobsView = Em.View.extend
  templateName: 'jobs'
  elementId: 'running-jobs'

Travis.QueueView = Em.View.extend
  templateName: 'queues/show'
  init: ->
    @_super.apply this, arguments
    @set 'controller', @get('controller').container.lookup('controller:queues')

require 'views/accounts'
require 'views/annotation'
require 'views/application'
require 'views/build'
require 'views/events'
require 'views/flash'
require 'views/job'
require 'views/log'
require 'views/repo'
require 'views/profile'
require 'views/stats'
require 'views/signin'
require 'views/top'
require 'views/status_images'
require 'views/status_image_input'
