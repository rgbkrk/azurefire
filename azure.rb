# Master source file for the azurefire website.

require 'rubygems'
require 'bundler/setup'

require 'sinatra'

require 'haml'
require 'sass'
require 'rdiscount'

configure :development do |c|
  require 'sinatra/reloader'
  c.also_reload 'settings.rb'
  c.also_reload 'nav.rb'
  c.also_reload 'honeypot.rb'
  c.also_reload 'model/*.rb'

  # Keep debugging output nice and current in Eclipse.
  $stdout.sync = true
end

configure :test do |c|
  # Don't produce log messages among that nice row of "rake test" dots.
  c.disable :logging
end

# Load required source files.

require_relative 'nav'
require_relative 'honeypot'

require_relative 'model/comment'
require_relative 'model/journal_post'
require_relative 'model/archive_index'
require_relative 'model/archive_query'
require_relative 'model/daily_quote'

# Site navigation and daily quote.

helpers do
  include NavigationHelper
  include Honeypot

  def timestamp
    Time.now
  end
end

before do
  @quote = DailyQuote.choose

  menu do
    nav 'news', :default => true
    nav 'archive'
    nav 'about'
  end
end

not_found { haml :'404' }

# Run stylesheets through scss.

get %r{/([^.]+).css} do |name|
  content_type 'text/css', :charset => 'utf-8'
  scss name.to_sym
end

# About page

get '/about' do
  haml :about
end

# News page

[ '/', '/news' ].each do |route|
  get route do
    @posts = ArchiveIndex.new.recent_posts(5)
    haml :news
  end
end

# Archive page

get %r{/archive(/([^/]+))?} do |_, query|
  i = ArchiveIndex.new
  @query = ArchiveQuery.new(query)
  @posts = i.posts_matching @query
  haml :archive
end

# Live markdown preview

post '/markdown-preview' do
  RDiscount.new(params[:body], :filter_html).to_html
end

# News post permalink

get '/:slug' do |slug|
  @navigate_as = '/news'
  @post = JournalPost.with_slug slug
  halt 404 unless @post

  @next, @prev = @post.next, @post.prev
  @js = ['single-post']

  @ts = timestamp
  @spinner = spinner(@ts, request.ip, slug)

  # Generate the hashed field name and CSS class factor for the name field. The
  # name CSS class should be a multiple of 5.
  @name_field = field_name(@spinner, 'name')
  @name_css = "comment-#{5 * (rand(10) + 1)}"

  # Similarly generate the body factor. Body CSS classes are multiples of 3.
  @body_field = field_name(@spinner, 'body')
  @body_css = "comment-#{3 * (rand(33) + 1)}"

  # And the submit button. The submit button's CSS class is a multiple of 7.
  @submit_field = field_name(@spinner, 'submit')
  @submit_css = "comment-#{7 * (rand(14) + 1)}"

  haml :single_post
end

# Comment post

post '/:slug' do |slug|
  @post = JournalPost.with_slug slug
  halt 404 unless @post

  # Detect the RSpec token. If it's present (and matches the application secret),
  # we're running in RSpec and can bypass spam detection.
  if params[:rspec_secret] == secret
    comment = Comment.new
    comment.name = params[:name]
    comment.content = params[:body]
    @post.add_comment comment
    redirect to("/#{slug}#comment-#{comment.number}")
  else
    # Spam detection.
  end
end
