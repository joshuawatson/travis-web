Travis.RequestController = Ember.ObjectController.extend
  requestClass: (->
    if @get('content.isAccepted')
      'accepted'
    else
      'rejected'
  ).property('content.isAccepted')

  type: (->
    if @get('isPullRequest')
      'Pull request'
    else
      'Push'
  ).property('isPullRequest')

  status: (->
    if @get('isAccepted')
      'Accepted'
    else
      'Rejected'
  ).property('isAccepted')

  message: (->
    message = @get('model.message')
    if Travis.config.pro && message == "private repository"
      ''
    else
      message
  ).property('model.message')


