cpto = require('crypto')
require('zappa').run 5555, ->
  @enable 'serve jquery'
  
  @get '/': ->
    @render index: {layout: no}

  users = {}
  @on disconnect: ->
    delete users[@id] 
    @emit reload_users: {users: users}
  
  @on 'set nickname': ->
    for u of users
      @data.nickname += '_' if users[u].nickname is @data.nickname

    users[@id] = @client

    @client.nickname = @data.nickname
    avatar_hash = cpto.createHash('md5').update(@client.nickname).digest 'hex'
    try
      @client.avatar      = "http://www.gravatar.com/avatar/#{avatar_hash}?d=monsterid"
    catch error
      @client.avatar      = "http://www.gravatar.com/avatar/0?d=monsterid"


    @broadcast  reload_users: {users: users}
    @emit       reload_users: {users: users}
  
  @on said: ->
    @broadcast said: {nickname: @client.nickname, avatar: @client.avatar, text: @data.text}
    @emit said: {nickname: @client.nickname, avatar: @client.avatar, text: @data.text}

  @client
    '/index.js': ->
      @connect()

      @on reload_users: ->
        $('#nicklist').html('')
        $('#nicklist').append "<p>#{@data.users[u].nickname}" for u of @data.users

      @on said: ->
        avatar = "<img src='#{@data.avatar}' />"
        unless $('#allow_codes').attr('checked')
          $div = $("<div>#{avatar}<p></p></div>").find('p').text("#{@data.nickname} --> #{@data.text}").parent()
        else
          $div = $("<div>#{avatar}<p>#{@data.nickname} --> #{@data.text}</p></div>")

        $('#panel').prepend $div
      $ =>
        @emit 'set nickname': {nickname: prompt 'Pick a nickname!'}
        
        $('#box').focus()
        
        $('button').click (e) =>
          @emit said: {text: $('#box').val()}
          $('#box').val('').focus()
          e.preventDefault()

  @stylus '/layout.css': '''
    body
      background #ddd
    form
      position absolute
      bottom 0
      left 0
      right 0
      margin 1em
      input, button
        font-size 1.2em !important
    #box
      width 50%

    #nicklist
      position absolute
      top 0
      left 0
      right 0
      height 100px
      margin 1em
      p
        float left
        background #aaa
        padding: .5em
        margin: .5em
    #panel
      position absolute
      left 0
      top 100px
      right 0
      bottom 110px
      background #eee
      overflow auto
      color #999
      margin 1em
      padding 1em
      div
        position relative
        padding: .5em
        margin: 1px
        p
          position absolute
          left 100px
          top 0
      div:first-child
        background: #d0d0d0
        color black
        font-size 1.2em
  '''
      
  @view index: ->
    doctype 5
    html ->
      head ->
        title 'PicoChat!'
        script src: '/socket.io/socket.io.js'
        script src: '/zappa/jquery.js'
        script src: '/zappa/zappa.js'
        script src: '/index.js'
        link rel: 'stylesheet', href: '/layout.css'
      body ->
        div id: 'nicklist'
        div id: 'panel'
        form ->
          p ->
            input id: 'box'
            button 'Send'
          p ->
            label for: 'allow_codes', 'Liberar codigos'
            input type: 'checkbox', id: 'allow_codes'
