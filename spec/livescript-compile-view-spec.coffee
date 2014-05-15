LivescriptCompileView = require '../lib/livescript-compile-view'
{WorkspaceView} = require 'atom'
fs = require 'fs'

describe "LivescriptCompileView", ->
  compiled = null
  editor   = null

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    atom.workspace = atom.workspaceView.model

    editor = atom.project.openSync('test.ls')
    compiled = new LivescriptCompileView editor.id

    waitsForPromise ->
      atom.packages.activatePackage('language-livescript')

  afterEach ->
    compiled.destroy()

  describe "renderCompiled", ->
    it "should compile the whole file and display compiled js", ->
      waitsFor ->
        done = false
        compiled.renderCompiled -> done = true
        return done
      , "Livescript should be compiled", 750

      runs ->
        expect(compiled.find('.line')).toExist()

  describe "saveCompiled", ->
    filePath = null
    beforeEach ->
      filePath = editor.getPath()
      filePath = filePath.replace ".ls", ".js"

    afterEach ->
      fs.unlink(filePath) if fs.existsSync(filePath)

    it "should compile and create a js file", ->
      waitsFor ->
        done = false
        compiled.saveCompiled -> done = true
        return done
      , "Compile on save", 750

      runs ->
        expect(fs.existsSync(filePath)).toBeTruthy()
