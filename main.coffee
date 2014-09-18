React = require 'react'
Docs = require './docs.coffee'

concatPath = require './concat-path.coffee'

{html, body, head, title,
 img, b, small, span, i, a, p,
 script, link, meta, div, button,
 fieldset, legend, label, input, form, textarea,
 table, thead, tbody, tr, th, td, tfoot,
 dl, dt, dd, ul, li,
 h1, h2, h3, h4, h5, h6} = React.DOM

Main = React.createClass
  getInitialState: ->
    editingPath: null

  startEditing: (path) ->
    @setState
      editingPath: path

  publish: ->
    # get password
    if not @pass
      @pass = prompt "Your GitHub password:"
      if @pass
        DOCS.password @pass

    # build tree and deploy
    DOCS.buildGitHubTree (err, tree) =>
      console.log err if err
      if not err
        DOCS.deploy tree, (err, res) =>
          console.log err, res

  render: ->
    (div className: 'row',
      (div className: 'fourth',
        (button
          className: 'deploy warning'
          onClick: @publish
        , 'Publish')
        (ul className: 'tree',
          (DocTree
            key: ''
            title: ''
            children: DOCS.doc_index[''].children
            onSelect: @startEditing
            defaultOpened: true)
        )
      )
      (div className: 'three-fourth',
        (Edit
          path: @state.editingPath
        )
      )
    )

DocTree = React.createClass
  getInitialState: ->
    opened: if @props.defaultOpened then true else false

  openTree: (e) ->
    e.preventDefault()
    @setState opened: !@state.opened

  editDocument: (e) ->
    e.preventDefault()
    @props.onSelect @props.key

  render: ->
    (li {},
      (a
        href: '#'
        onClick: @openTree
      , if @state.opened then '⇡' else '⇣') if @props.children.length
      (a
        href: '#'
        onClick: @editDocument
      , @props.title + '/')
      (ul {},
        (DocTree
          key: concatPath [@props.key, child.slug]
          children: DOCS.doc_index[concatPath [@props.key, child.slug]].children
          title: child.slug
          onSelect: @props.onSelect
        ) for child in @props.children
      ) if @state.opened
    )

Edit = React.createClass
  getInitialState: ->
    raw: ''

  componentDidMount: ->
    @fetch @props.path

  componentWillReceiveProps: (nextProps) ->
    @setState raw: ''
    @fetch nextProps.path

  fetch: (path) ->
    if not path
      return
    DOCS.fetchRaw path, (raw) =>
      @setState raw: raw

  handleChange: (e) ->
    @setState raw: e.target.value

  save: (e) ->
    e.preventDefault() if e
    DOCS.modifyRaw @props.path, @state.raw

  render: ->
    (div className: 'edit',
      (form
        onSubmit: @save
      ,
        (fieldset {},
          (label {}, @props.path)
          (textarea
            value: @state.raw
            onChange: @handleChange
          )
          (button
            className: 'primary'
          , 'Save')
        )
      ) if @props.path
    )

# github client
gh_data = /([\w-_]+)\.github\.((io|com)\/)([^/]*)\/?([^/]*)/.exec(location.href)
if gh_data
  user = gh_data[1]
  repo = if gh_data[5] then gh_data[4] else "#{user}.github.#{gh_data[3]}"
else
  user = localStorage.getItem location.href + '-user'
  if not user
    user = prompt "Your GitHub username for this blog:"
    localStorage.setItem location.href + '-user', user

  repo = localStorage.getItem location.href + '-repo'
  if not repo
    repo = prompt "The name of the repository in which this blog is hosted:"
    localStorage.setItem location.href + '-repo', repo

  console.log "will connect to the repo #{user}/#{repo}"

DOCS = new Docs user, repo
DOCS.init ->
  React.renderComponent Main(), document.body