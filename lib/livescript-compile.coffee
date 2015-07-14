url         = require 'url'
querystring = require 'querystring'
{CompositeDisposable} = require 'atom'

LivescriptCompileView = require './livescript-compile-view'

module.exports =
  configDefaults:
    grammars: [
      'source.livescript'
      'text.plain'
      'text.plain.null-grammar'
    ]
    noTopLevelFunctionWrapper: true
    compileOnSave: false
    focusEditorAfterCompile: false

  activate: ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-text-editor', 'livescript-compile:compile': => @display()

    atom.workspace.addOpener (uriToOpen) ->
      {protocol, host, pathname} = url.parse uriToOpen
      pathname = querystring.unescape(pathname) if pathname

      return unless protocol is 'livescript-compile:'
      new LivescriptCompileView(pathname.substr(1))

  display: ->
    editor     = atom.workspace.getActiveTextEditor()
    activePane = atom.workspace.getActivePane()

    return unless editor?

    grammars = atom.config.get('livescript-compile.grammars') or []
    console.log editor.getGrammar().scopeName
    unless (grammar = editor.getGrammar().scopeName) in grammars
      console.warn("Cannot compile non-LiveScript to Javascript")
      return

    uri = "livescript-compile://editor/#{editor.id}"

    # If a pane with the uri
    pane = atom.workspace.paneForURI uri
    # If not, always split right
    pane ?= activePane.splitRight()

    atom.workspace.openURIInPane(uri, pane, {}).done (livescriptCompileView) ->
      if livescriptCompileView instanceof LivescriptCompileView
        livescriptCompileView.renderCompiled()

        if atom.config.get('livescript-compile.compileOnSave')
          livescriptCompileView.saveCompiled()
        if atom.config.get('livescript-compile.focusEditorAfterCompile')
          activePane.activate()
