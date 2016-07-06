temp   = require "temp"
wrench = require "wrench"
path   = require "path"
{TextEditor} = require 'atom'

LivescriptCompileView = require '../lib/livescript-compile-view'

describe "LivescriptCompile", ->
  beforeEach ->
    fixturesPath = path.join __dirname, "fixtures"
    tempPath     = temp.mkdirSync "atom"
    wrench.copyDirSyncRecursive fixturesPath, tempPath, forceDelete: true
    atom.project.setPaths [tempPath]

    jasmine.unspy window, "setTimeout"

    atom.workspaceView = atom.views.getView(atom.workspace)
    spyOn(LivescriptCompileView.prototype, "renderCompiled")

    jasmine.attachToDOM(atom.workspaceView)

    atom.packages.activatePackage('livescript-compile').then ->
      atom.packages.activatePackage('language-livescript')

  describe "should open a new pane", ->
    beforeEach ->
      jasmine.attachToDOM(atom.workspaceView)

      editor = null
      waitsForPromise ->
        atom.workspace.open('test.ls').then (e) ->
          editor = e

      runs ->
        atom.commands.dispatch atom.views.getView(editor), 'livescript-compile:compile'

      waitsFor ->
        LivescriptCompileView::renderCompiled.callCount > 0

    it "should always split to the right", ->
      runs ->
        expect(atom.workspace.getPaneItems()).toHaveLength 2

    it "should have the same instance", ->
      runs ->
        [editor, compiled] = atom.workspace.getPaneItems()
        expect(editor).toBeInstanceOf(TextEditor)
        expect(compiled).toBeInstanceOf(LivescriptCompileView)

    it "should have the same path as active pane", ->
      runs ->
        [editor, compiled] = atom.workspace.getPaneItems()
        expect(compiled.getPath()).toBe atom.workspace.getActivePaneItem().getPath()

    it "should focus on compiled pane", ->
      runs ->
        [editor, compiled] = atom.workspace.getPaneItems()
        expect(compiled).toHaveFocus()

  describe "when the focus editor option is true", ->
    beforeEach ->
      atom.config.set "livescript-compile.focusEditorAfterCompile", true
      jasmine.attachToDOM(atom.workspaceView)

      editor = null
      waitsForPromise ->
        atom.workspace.open("test.ls").then (e) ->
          editor = e

      runs ->
        atom.commands.dispatch atom.views.getView(editor), 'livescript-compile:compile'

      waitsFor ->
        LivescriptCompileView::renderCompiled.callCount > 0

    it "should focus on editor pane", ->
      runs ->
        [editor, compiled] = atom.workspace.getPaneItems()
        expect(atom.views.getView(editor)).toHaveFocus()

  describe "when the editor's grammar is not livescript", ->
    it "should not preview compiled js", ->
      atom.config.set "livescript-compile.grammars", []
      jasmine.attachToDOM(atom.workspaceView)

      waitsForPromise ->
        atom.workspace.open "test.ls"

      runs ->
        spyOn(atom.workspace, "open").andCallThrough()
        atom.commands.dispatch atom.workspaceView, 'markdown-preview:show'
        expect(atom.workspace.open).not.toHaveBeenCalled()
