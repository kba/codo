FS      = require 'fs'
Path    = require 'path'
mkdirp  = require 'mkdirp'
_       = require 'underscore'
hamlc   = require 'haml-coffee'
walkdir = require 'walkdir'
Mincer  = require 'mincer'
Nib     = require 'nib'
Theme   = require './_theme'

module.exports = class Theme.Templater

  sourceOf: (subject) ->
    localDir = Path.join(@themeLocal, subject)
    if FS.existsSync localDir
      return localDir
    return Path.join(__dirname, '..', subject) 

  constructor: (@environment) ->
    @destination = @environment.options.output
    @themeLocal = @environment.options['theme-local']
    Mincer.StylusEngine.configure (stylus) => stylus.use Nib()
    Mincer.CoffeeEngine.configure bare: false

    @JST = []

    templates = @sourceOf('templates')

    for template in walkdir.sync(templates)
      unless FS.lstatSync(template).isDirectory()
        relative = Path.relative(templates, template)
        dirname  = Path.dirname(relative)
        basename = Path.basename(template, '.hamlc')

        keyword = basename
        keyword = dirname + '/' + basename unless dirname == '.'

        @JST[keyword] = hamlc.compile FS.readFileSync(template, 'utf8'),
          escapeAttributes: false

  compileCSS: (from, to=false) ->
      @compileAsset('assets/stylesheets', from, to)

  compileJavascript: (from, to=false) ->
      @compileAsset('assets/javascript', from, to)

  compileAsset: (folder, from, to=false) ->
    mincer = new Mincer.Environment()
    mincer.appendPath @sourceOf(folder)

    asset = mincer.findAsset(from)
    file  = Path.join(@destination, Path.basename(folder), to || from)
    dir   = Path.dirname(file)

    mkdirp.sync(dir)
    FS.writeFileSync(file, asset.buffer)

  # Render the given template with the context and the
  # global context object merged as template data. Writes
  # the file as the output filename.
  #
  # @param [String] template the template name
  # @param [Object] context the context object
  # @param [String] filename the output file name
  #
  render: (template, context = {}, filename = '') ->
    html = @JST[template](context)

    if filename.length > 0
      file = Path.join @destination, filename
      dir  = Path.dirname(file)

      mkdirp.sync(dir)
      FS.writeFileSync(file, html)

    html
