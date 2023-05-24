App.invoicer = App.cable.subscriptions.create "InvoicerChannel",
  connected: ->
    console.log('CONNECTED')
    # Called when the subscription is ready for use on the server
    jQuery('body').removeClass('invoicer--connected')
    jQuery('body').addClass('invoicer--connected')

  disconnected: ->
    # Called when the subscription has been terminated by the server
    jQuery('body').addClass('invoicer--disconnected')
    jQuery('body').removeClass('invoicer--disconnected')

  received: (data) ->
    console.log('Data Received:', data)

    # Called when there's incoming data on the websocket for this channel
    switch data.action
      when 'init' then jQuery(window).trigger('invoicer:jobs:init', { jobs: data.payload })
      when 'enqueue' then jQuery(window).trigger('invoicer:jobs:enqueue', data)
      when 'status' then jQuery(window).trigger('invoicer:jobs:status', data)
      when 'delete' then jQuery(window).trigger('invoicer:jobs:delete', data)
      else break

  # start: ()
