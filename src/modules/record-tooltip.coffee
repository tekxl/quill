Quill   = require('../quill')
Tooltip = require('./tooltip')
Microm = require('../../bower_components/microm/dist/microm')
_       = Quill.require('lodash')
dom     = Quill.require('dom')
Delta   = Quill.require('delta')
Range   = Quill.require('range')


class RecordTooltip extends Tooltip
  @DEFAULTS:
    template:
     '
      <div  class="record-tooltip-player">
        <div class="record-tooltip-player-controls">
          <div class="record-tooltip-player-micro">
            <i class="fa fa-microphone-slash record-micro"></i>
          </div>
          <div class="box">
  					<input type="file" name="file-5[]" id="file-5" class="inputfile inputfile-4" data-multiple-caption="{count} files selected" accept="audio/*" />
  					<label for="file-5">
              <figure>
                <svg xmlns="http://www.w3.org/2000/svg" width="20" height="17" viewBox="0 0 20 17">
                <path d="M10 0l-5.2 4.9h3.3v5.1h3.8v-5.1h3.3l-5.2-4.9zm9.3 11.5l-3.2-2.1h-2l3.4 2.6h-3.5c-.1 0-.2.1-.2.1l-.8 2.3h-6l-.8-2.2c-.1-.1-.1-.2-.2-.2h-3.6l3.4-2.6h-2l-3.2 2.1c-.4.3-.7 1-.6 1.5l.6 3.1c.1.5.7.9 1.2.9h16.3c.6 0 1.1-.4 1.3-.9l.6-3.1c.1-.5-.2-1.2-.7-1.5z"/>
                </svg>
              </figure>
              <span>Choose a file&hellip;</span>
            </label>
  				</div>
          <div class="record-controls">
            <a role="button" class="record-play fa fa-play"></a>
            <a role="button" class="record-delete fa fa-remove"></a>
          </div>
          <div class="record-time-counter">00:00:00</div>
        </div>
      </div>
      <a href="javascript:;" class="cancel">Cancel</a>
      <a href="javascript:;" class="insert">Insert</a>'

  constructor: (@quill, @options) ->
    @options = _.defaults(@options, Tooltip.DEFAULTS)
    super(@quill, @options)
    @timer = @container.querySelector('.record-time-counter')
    @is_record = false
    dom(@container).addClass('ql-record-tooltip')
    unless @microm
      @microm = new Microm
    this.initListeners()

  initListeners: ->
    @initJs()
    @quill.on('record_data_register', _.bind(this.moduleResult, this))
    dom(@container.querySelector('.insert')).on('click', _.bind(this.sendBlob, this))
    dom(@container.querySelector('.cancel')).on('click', _.bind(this.hide, this))
    dom(@container.querySelector('.record-play')).on('click', _.bind(this.play, this))
    dom(@container.querySelector('.record-delete')).on('click', _.bind(this.delete, this))
    dom(@container.querySelector('.record-micro')).on('click', _.bind(this.start, this))
    @quill.onModuleLoad('toolbar', (toolbar) =>
      toolbar.initFormat('record', _.bind(this._onToolbar, this))
    )

  startRecording: ()->
    @deleteError()
    @microm.record().then () =>
      @is_record = true
      @quill.emit "record_voice","record start"
      setTimeout(@updateCurrentTime, 1000);
    .catch () =>
      @quill.emit "record_voice","record error"


  stopRecording: ()->
    @is_record = false
    @microm.stop().then (voice) =>
      @quill.emit "record_voice","record stop"

  sendBlob: ()->
    @microm.getMp3().then (mp3) =>
      dom(@container.querySelector('.record-tooltip-player')).addClass('record-data-sending')
      #@quill.emit "record_data",mp3.blob
      #this.hide()
      @registerData mp3.blob,"mp3"
      this.hide()

  # registerData: (blob,type) ->
  #   key = @generateKey()
  #   key_mp3 =  key+ '.'+type
  #   data =
  #     'filename': key_mp3,
  #     'filetype':'audio/'+type
  #   xhr_ = new XMLHttpRequest()
  #   xhr_.open 'PUT', @url
  #   xhr_.setRequestHeader 'Content-Type', 'application/json'
  #   xhr_.onreadystatechange = (aEvt) =>
  #     if xhr_.readyState == 4
  #       if xhr_.status == 200
  #         @uploadWithUrl blob,data.presigned_url,data.public_url,type
  #       else
  #         @quill.emit "record_data_register","error"
  #   xhr_.send data
  #
  # uploadWithUrl: (file,presignedUrl, publicUrl,type) ->
  #   # create PUT request to S3
  #   xhr = new XMLHttpRequest()
  #   xhr.open 'PUT', presignedUrl
  #   xhr.setRequestHeader 'Content-Type', 'audio/'+type
  #   xhr.onreadystatechange = (aEvt) =>
  #     if xhr.readyState == 4
  #       if xhr.status == 200
  #         if type is "mp3"
  #           @registerData mp3.blob,"ogg"
  #         else
  #           @quill.emit "record_data_register",publicUrl
  #        else
  #         @quill.emit "record_data_register","error"
  #   xhr.send file
  #   return

  moduleResult: (message)->
    dom(@container.querySelector('.record-tooltip-player')).removeClass('record-data-sending')
    if message  is "error"
      dom(@container.querySelector('.record-tooltip-player')).addClass('record-data-sending-error')
    else
      this.hide()


  play: ()->
    @microm.play() if @microm.player

  hide: ()->
    @resetTimer()
    @deleteError()
    super

  generateKey: ()->
    d = new Date().getTime()
    uuid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c)->
        r = (d + Math.random()*16)%16 | 0;
        d = Math.floor(d/16);
        return (c=='x' ? r : (r&0x3|0x8)).toString(16);
      )
    return uuid;

  updateCurrentTime: ()=>
    if @is_record
      myTime = @timer.innerText
      ss = myTime.split(":")
      dt = new Date()
      dt.setHours(ss[0])
      dt.setMinutes(ss[1])
      dt.setSeconds(ss[2])

      dt2 = new Date(dt.valueOf() + 1000)
      ts = dt2.toTimeString().split(" ")[0]
      @timer.innerText = ts
    setTimeout(@updateCurrentTime, 1000) if @is_record

  start: ()->
    if dom(@container.querySelector('.record-micro')).hasClass('start-animation')
      dom(@container.querySelector('.record-micro')).removeClass('start-animation')
      @container.querySelector('.record-play').style.display = "inline"
      @container.querySelector('.record-delete').style.display = "inline"
      @stopRecording()
    else
      dom(@container.querySelector('.record-micro')).addClass('start-animation')
      @container.querySelector('.record-play').style.display = "none"
      @container.querySelector('.record-delete').style.display = "none"
      @startRecording()

  delete: ()->
    @microm = new Microm
    @resetTimer()

  resetTimer: ()->
    @timer.innerText = "00:00:00" if @timer

  deleteError: ()->
    if dom(@container.querySelector('.record-tooltip-player')).hasClass('record-data-sending-error')
      dom(@container.querySelector('.record-tooltip-player')).removeClass('record-data-sending-error')


  _onToolbar: (range, value) ->
    this.show()


  initJs: () ->
    inputs = document.querySelectorAll('.inputfile' )
    for input in inputs
      label	 = input.nextElementSibling
      labelVal = label.innerHTML
      input.addEventListener 'change', ( e )->
        fileName = ''
        fileName = e.target.value.split( '\\' ).pop()
        if fileName
          label.querySelector( 'span' ).innerHTML = fileName
        else
          label.innerHTML = labelVal  

      input.addEventListener 'focus', ( e )->
        input.classList.add( 'has-focus' )

      input.addEventListener 'blur', ( e )->
        input.classList.remove( 'has-focus' )


Quill.registerModule('record-tooltip', RecordTooltip)
module.exports = RecordTooltip
