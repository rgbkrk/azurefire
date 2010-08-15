require 'tests/web_test_case'

require 'model/journal_post'
require 'model/comment'

class LatestNewsTest < WebTestCase
  
  def test_default_navigation
    ['/', '/news', '/news/latest'].each do |link|
      get link
      
      assert_css 'ul.main-navigation li a.current'
      assert_equal '/news', @node['href']
      
      assert_css 'ul.sub-navigation li a.current'
      assert_equal '/news/latest', @node['href']
    end
  end
  
  def test_render_post
    p1 = JournalPost.new
    p1.title = 'First title'
    p1.body = '*things*'
    p1.save
    
    get '/news/latest'
    
    assert_css '.post h2.title'
    assert_equal 'First title', @node.content
    
    assert_css '.post em'
    assert_equal 'things', @node.content
  end
  
  def test_post_controls
    p1 = JournalPost.new
    p1.title = 'foo'
    p1.body = 'bar'
    p1.timestamp = Time.parse('Aug 1, 2010 10am')
    p1.save
    
    5.times do
      c = Comment.new
      c.body = 'you suck!'
      c.journal_post = p1
      c.save
    end
    
    login
    get '/news/latest'
    
    parse
    nodes = @doc.css('ul.controls li a')
    names = nodes.collect { |each| each.content }
    links = nodes.collect { |each| each['href'] }
    
    assert_equal ['comments (5)', 'edit'], names
    assert_equal ['/news/2010/08/01/foo', '/news/edit/2010/08/01/foo'], links
  end
  
  def test_anonymous_post_controls
    p1 = JournalPost.new
    p1.title = 'foo'
    p1.body = 'bar'
    p1.timestamp = Time.parse('Aug 1, 2010 10am')
    p1.save
    
    get '/news/latest'
    
    parse
    nodes = @doc.css('ul.controls li a')
    names = nodes.collect { |each| each.content }
    links = nodes.collect { |each| each['href'] }
    
    assert_equal ['comments (0)'], names
    assert_equal ['/news/2010/08/01/foo'], links
  end
  
end