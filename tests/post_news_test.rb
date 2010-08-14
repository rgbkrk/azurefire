require 'tests/web_test_case'

require 'model/journal_post'
require 'model/comment'

class PostNewsTest < WebTestCase
  
  def setup
    super
    @p = JournalPost.new
    @p.title = 'hurf'
    @p.body = 'durf durf durf'
    @p.timestamp = Time.parse 'Aug 1, 2010 10am'
    @p.save
  end
  
  def test_single_post_view
    get '/news/2010/08/01/hurf'
    assert last_response.ok?
    
    assert_css '.post h2.title'
    assert_equal 'hurf', @node.content
    
    assert_css '.post p'
    assert_equal 'durf durf durf', @node.content
  end
  
  def test_missing_post
    get '/news/2000/10/01/blah'
    assert last_response.not_found?
  end
  
  def test_show_comments
    c1 = Comment.new
    c1.body = '`code!`'
    c1.name = 'mcfeegle'
    c1.journal_post = @p
    c1.save
    
    c2 = Comment.new
    c2.body = '*this is emphasized*'
    c2.name = 'rogr'
    c2.journal_post = @p
    c2.save
    
    get '/news/2010/08/01/hurf'
    
    assert_css 'ul.comments li code'
    assert_equal 'code!', @node.content
    
    assert_css 'ul.comments li em'
    assert_equal 'this is emphasized', @node.content
    
    assert_css 'ul.comments li.new form'
  end
  
  def test_add_comment
    post '/news/2010/08/01/hurf', :name => 'mcfoo', :body => '*i disagree!*', :submit => 'Submit'
    follow_redirect!
    
    assert_css 'ul.comments li em'
    assert_equal 'i disagree!', @node.content
  end
  
end