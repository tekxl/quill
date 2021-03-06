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
      <div class="preview">
        <a class="audio-containers" href="#">
          event
        </a>
        <span>Preview</span>
      </div>
      <a href="javascript:;" class="cancel">Cancel</a>
      <a href="javascript:;" class="play">Play</a>
      <a href="javascript:;" class="insert">Insert</a>'

  constructor: (@quill, @options) ->
    @options = _.defaults(@options, Tooltip.DEFAULTS)
    super(@quill, @options)
    @preview = @container.querySelector('.preview')
    @audio = @container.querySelector('.audio-containers')
    dom(@container).addClass('ql-record-tooltip')
    #@microm = new Microm
    unless @microm
      @microm = new Microm
    this.initListeners()

  initListeners: ->
    dom(@container.querySelector('.insert')).on('click', _.bind(this.sendBlob, this))
    dom(@container.querySelector('.cancel')).on('click', _.bind(this.hide, this))
    dom(@audio).on('click', _.bind(this.recordingEvent, this))
    dom(@container.querySelector('.play')).on('click', _.bind(this.play, this))
    @quill.onModuleLoad('toolbar', (toolbar) =>
      toolbar.initFormat('record', _.bind(this._onToolbar, this))
    )


  recordingEvent: ->
    if dom(@audio).hasClass('start-recording')
      dom(@audio).removeClass('start-recording')
      @stopRecording()
    else
      dom(@audio).addClass('start-recording')
      @startRecording()

  startRecording: ()->
    console.log 'recording step 3'
    @microm.record().then () ->
      console.log 'recording ...'
    .catch () ->
      console.log 'error recording'


  stopRecording: ()->
    @microm.stop().then (voice) ->
      console.log 'darex',voice

  sendBlob: ()->
    @microm.getMp3().then (mp3) =>
      myRecordEvent = new CustomEvent("myEventName",
      {
          'data': mp3.blob
      })
      console.log myRecordEvent
      @audio.dispatchEvent(myRecordEvent);


  play: ()->
    @microm.play()


  _onToolbar: (range, value) ->
    this.show()


Quill.registerModule('record-tooltip', RecordTooltip)
module.exports = RecordTooltip
