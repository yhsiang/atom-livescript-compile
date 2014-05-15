temp   = require "temp"
wrench = require "wrench"
path   = require "path"

LivescriptCompileView = require '../lib/livescript-compile-view'
{WorkspaceView} = require 'atom'

describe "LivescriptCompile", ->
  beforeEach ->
    fixturesPath = path.join __dirname, "fixtures"
    tempPath     = temp.mkdirSync "atom"
    wrench.copyDirSyncRecursive fixturesPath, tempPath, forceDelete: true
    atom.project.setPath tempPath

    jasmine.unspy window, "setTimeout"

    atom.workspaceView = new WorkspaceView
    atom.workspace     = atom.workspaceView.model
    spyOn(LivescriptCompileView.prototype, "renderCompiled")

    waitsForPromise ->
      atom.packages.activatePackage('livescript-compile')

    waitsForPromise ->
      atom.packages.activatePackage('language-livescript')

    atom.workspaceView.attachToDom()

  describe "should open a new pane", ->
    beforeEach ->
      atom.workspaceView.attachToDom()

      waitsForPromise ->
        atom.workspace.open "test.ls"

      runs ->
        atom.workspaceView.getActiveView().trigger "livescript-compile:compile"

      waitsFor ->
        LivescriptCompileView::renderCompiled.callCount > 0

    it "should always split to the right", ->
      runs ->
        expect(atom.workspaceView.getPanes()).toHaveLength 2
        [editorPane, compiledPane] = atom.workspaceView.getPanes()

        expect(editorPane.items).toHaveLength 1

        compiled = compiledPane.getActiveItem()

    it "should have the same instance", ->
      runs ->
        [editorPane, compiledPane] = atom.workspaceView.getPanes()
        compiled = compiledPane.getActiveItem()

        expect(compiled).toBeInstanceOf(LivescriptCompileView)

    it "should have the same path as active pane", ->
      runs ->
        [editorPane, compiledPane] = atom.workspaceView.getPanes()
        compiled = compiledPane.getActiveItem()

        expect(compiled.getPath()).toBe atom.workspaceView.getActivePaneItem().getPath()

    it "should focus on compiled pane", ->
      runs ->
        [editorPane, compiledPane] = atom.workspaceView.getPanes()
        compiled = compiledPane.getActiveItem()

        expect(compiledPane).toHaveFocus()

    it "should focus editor when option is set", ->
      runs ->
        atom.config.set "livescript-compile.focusEditorAfterCompile", true
        [editorPane, compiledPane] = atom.workspaceView.getPanes()

        expect(editorPane).toHaveFocus()

  describe "when the editor's grammar is not livescript", ->
    it "should not preview compiled js", ->
      atom.config.set "livescript-compile.grammars", []
      atom.workspaceView.attachToDom()

      waitsForPromise ->
        atom.workspace.open "test.ls"

      runs ->
        spyOn(atom.workspace, "open").andCallThrough()
        atom.workspaceView.getActiveView().trigger 'markdown-preview:show'
        expect(atom.workspace.open).not.toHaveBeenCalled()
