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
            <a role="button" class="record-play fa fa-play"></a>
            <i class="fa fa-microphone-slash record-micro"></i>
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
    console.log 'constructor',@timer
    dom(@container).addClass('ql-record-tooltip')
    unless @microm
      @microm = new Microm
    this.initListeners()

  initListeners: ->
    dom(@container.querySelector('.insert')).on('click', _.bind(this.sendBlob, this))
    dom(@container.querySelector('.cancel')).on('click', _.bind(this.hide, this))
    dom(@container.querySelector('.record-play')).on('click', _.bind(this.play, this))
    dom(@container.querySelector('.record-delete')).on('click', _.bind(this.delete, this))
    dom(@container.querySelector('.record-micro')).on('click', _.bind(this.start, this))
    @quill.onModuleLoad('toolbar', (toolbar) =>
      toolbar.initFormat('record', _.bind(this._onToolbar, this))
    )

  startRecording: ()->
    @microm.record().then () =>
      @is_record = true
      console.log @microm
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
      @quill.emit "record_data",mp3.blob
    this.hide()

  play: ()->
    @microm.play() if @microm.player

  hide: ()->
    @resetTimer()
    super

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
      @stopRecording()
    else
      dom(@container.querySelector('.record-micro')).addClass('start-animation')
      @startRecording()

  delete: ()->
    @microm = new Microm
    @resetTimer()

  resetTimer: ()->
    @timer.innerText = "00:00:00" if @timer


  _onToolbar: (range, value) ->
    this.show()


Quill.registerModule('record-tooltip', RecordTooltip)
module.exports = RecordTooltip
