Quill   = require('../quill')
Tooltip = require('./tooltip')
_       = Quill.require('lodash')
dom     = Quill.require('dom')
Delta   = Quill.require('delta')
Range   = Quill.require('range')


class MediaTooltip extends Tooltip
  @DEFAULTS:
    template:
     '<input class="input" type="textbox">
      <div class="preview">
        <span>Preview</span>
      </div>
      <a href="javascript:;" class="cancel">Cancel</a>
      <a href="javascript:;" class="insert">Insert</a>'

  @NOEMBED_URL = '//noembed.com/embed'

  constructor: (@quill, @options) ->
    @options = _.defaults(@options, Tooltip.DEFAULTS)
    super(@quill, @options)
    @preview = @container.querySelector('.preview')
    @textbox = @container.querySelector('.input')
    dom(@container).addClass('ql-media-tooltip')

    @request = new XMLHttpRequest()
    @embedUrl = null

    this.initListeners()

  initListeners: ->
    dom(@container.querySelector('.insert')).on('click', _.bind(this.insertVideo, this))
    dom(@container.querySelector('.cancel')).on('click', _.bind(this.hide, this))
    dom(@textbox).on('input', _.bind(this._getOEmbed, this))
    this.initTextbox(@textbox, this.insertVideo, this.hide)
    @quill.onModuleLoad('toolbar', (toolbar) =>
      toolbar.initFormat('media', _.bind(this._onToolbar, this))
    )

  insertVideo: ->
    return unless @embedUrl
    @range = new Range(0, 0) unless @range?   # If we lost the selection somehow, just put image at beginning of document
    if @range
      @preview.innerHTML = '<span>Preview</span>'
      @textbox.value = ''
      index = @range.end
      @quill.insertEmbed(index, 'media', @embedUrl, 'user')
      @quill.setSelection(index + 1, index + 1)

    @embedUrl = null
    this.hide()

  _onToolbar: (range, value) ->
    if value
      @textbox.value = 'http://' unless @textbox.value
      this.show()
      @textbox.focus()
      _.defer( =>
        @textbox.setSelectionRange(@textbox.value.length, @textbox.value.length)
      )
    else
      @quill.deleteText(range, 'user')

  _preview: ->
    return unless @embedUrl
    if @preview.firstChild.tagName == 'IFRAME'
      @preview.firstChild.setAttribute('src', @embedUrl)
    else
      iframe = document.createElement('iframe')
      iframe.setAttribute('src', @embedUrl)
      iframe.setAttribute('frameborder', '0')
      @preview.replaceChild(iframe, @preview.firstChild)

  _normalizeURL: (url) ->
    # For now identical to link-tooltip but will change when we allow data uri
    url = 'http://' + url unless /^https?:\/\//.test(url)
    return url

  _getOEmbed: ->
    url = this._normalizeURL(@textbox.value)
    url = window.encodeURIComponent url

    @request.abort()
    @request.open 'GET', "#{MediaTooltip.NOEMBED_URL}?url=#{url}", true

    @request.onreadystatechange = (aEvt) =>
      if @request.readyState == 4
         if @request.status == 200
          try
            json = JSON.parse @request.responseText
            @embedUrl = @_getEmbedUrlFromHTML(json.html || '')
            @_preview()
          catch

    @request.send(null)

  _getEmbedUrlFromHTML: (html) ->
    reg = /<iframe.*src="([^"']*)".*>.*<\/iframe>/g
    result = reg.exec(html)

    return result[1]

Quill.registerModule('media-tooltip', MediaTooltip)
module.exports = MediaTooltip
