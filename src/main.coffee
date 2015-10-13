fs = require 'fs'
path = require 'path'
readdirp = require 'readdirp'
mkdirp = require 'mkdirp'
{exec} = require 'child_process'
Promise = require 'bluebird'

argv = require('minimist') process.argv.slice(2),
  alias:
    cdb: 'c'
    outdir: 'o'
    help: 'h'
  default:
    cdb: "/cdb"
    outdir: "/cdb/backup/models"

help = """
clean-cdb

Moves older revisions of CDB model files to a backup directory

Usage: coffee src/main.coffee [OPTIONS]

Options
-c, --cdb [DIR]             Location of CDB, default is /cdb
-o, --outdir [DIR]          Output directory for backup, default is /cdb/backup/models
-h, --help                  Shows this help message
"""

if argv.help
  console.log help
  process.exit 0

get_id_and_rev = (model) ->
  match = model.match /^([^_]+)_(\d\d)\.mi/
  if match
    [match[1], parseInt(match[2])]

get_models = ->
  new Promise (resolve, reject) ->
    entries = {}
    remove = []

    options =
      root: path.join argv.cdb, 'models'
      fileFilter: '*.mi'

    stream = readdirp(options)
    .on 'data', (entry) ->
      res = get_id_and_rev entry.name
      if res
        [id, rev] = res
        if not entries[id]
          entries[id] = []
        if not isNaN(rev)
          entries[id].push {rev: rev, path: entry.fullPath}
      else
        remove.push entry.fullPath
    .on 'error', (err) ->
      reject err
    .on 'end', (e) ->
      for k, v of entries
        v.sort (a, b) -> a.rev - b.rev
        v.pop()
        for entry in v
          remove.push entry.path
      resolve remove

move_file = (source, target) ->
  new Promise (resolve, reject) ->
    #console.log "moving #{path.basename source}"
    child = exec "mv #{source} #{target}", (err, stdout, stderr) ->
      if err
        console.log "error moving #{path.basename source} #{err}"
      resolve()

move_files = (files) ->
  current = Promise.fulfilled()
  promises = files.map (f) ->
    current = current.then ->
      target = path.join argv.outdir, path.basename(f)
      move_file(f, target)
    current
  Promise.all(promises)

backup = (files) ->
  if not fs.existsSync(argv.outdir)
    mkdirp.sync argv.outdir
  move_files files

get_models()
.then (files) ->
  if argv.backup
    backup files
