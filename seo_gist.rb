require "bundler"
Bundler.require

class SEOGist < Sinatra::Base
  enable :inline_templates
  
  helpers do
    include Rack::Utils
  end
  
  get '/' do
    @id = params[:gist_id]
    if @id && !@id.empty?
      @gist = FriendlyGist.new(@id)
    end
    haml :index
  end
end

class FriendlyGist
  ScriptInclude = %{<script src="https://gist.github.com/%s.js"></script>}
  include HTTParty
  base_uri 'https://gist.github.com'

  attr_reader :id, :data, :script, :raw
  
  def initialize(id)
    @id = id
    @script = ScriptInclude % id
    @data = get_gist
    @raw = get_raw
  end

private
  def get_raw
    return nil unless @data
    @data['files'].inject('') do |r, f|
      r + "File: %s\n%s\n\n%s\n\n" % [f, ('-' * (6 + f.length)), get_raw_data(f)]
    end
  end
  
  def get_raw_data(file)
    r = self.class.get '/raw/%s/%s' % [@id, Rack::Utils.escape(file)]
    r.ok? ? r : ''
  end
  
  def get_gist
    r = self.class.get '/%s.json' % @id
    r.ok? ? r : nil
  end
end

__END__
@@layout
%html
  %head
    :css
      body{
      	margin:50px;
        padding:0;
      	font:14px/18px "Lucida Grande", verdana, arial, helvetica, sans-serif;
      	color:#222;
      	background-color:#222;        
        }
      h1,h2{
      	letter-spacing:-0.07em;
      	font:12px/16px "Lucida Grande", verdana, arial, helvetica, sans-serif;
      	color:#fff;
      	}
      	h1{font-size:200%;}
      	h2{font-size:125%;}
      	pre{
      	  margin:15px 0;
      	  background:#fff;
      	  padding:10px;
      	  }
      	form{
          margin:25px 0 45px;
          background:#ddd;
          border:3px solid #aaa;
          padding:10px;
      	  }
      	label{font-size:16px;margin-right:20px}
      	input[type="text"]{
      	  font-size:24px;
      	  border:2px solid #ccc;
      	  }
      	input[type="submit"]{
      	  font-size:18px
      	  }
      	a{color:#82A51B;font-weight:bold;}
      	small{display:block;color:#999}
    %script{src:'https://www.google.com/jsapi', type:'text/javascript'}
    :javascript
      google.load('jquery', '1');
    :javascript
      //http://www.codingforums.com/archive/index.php/t-105808.html
      function SelectText(element) {
        var text = document.getElementById(element);
        if ($.browser.msie) {
          var range = document.body.createTextRange();
          range.moveToElementText(text);
          range.select();
        } else if ($.browser.mozilla || $.browser.opera) {
          var selection = window.getSelection();
          var range = document.createRange();
          range.selectNodeContents(text);
          selection.removeAllRanges();
          selection.addRange(range);
        } else if ($.browser.safari) {
          var selection = window.getSelection();
          selection.setBaseAndExtent(text, 0, text, 1);
        }
      }
      $(document).ready(function(){ 
        $('#select').click(function(e){
          SelectText('embed');
          e.preventDefault();
        });
      });
    %title "SEO Friendly Gist"
  %body
    %h1 SEO Friendly Gists
    %h2 Generate a gist include that uses noscript and stuff.
    = yield

@@index
%span.form
  %form{:action => '/'}
    %label{for:'gist_id'} Gist ID
    %input{type:'text', id:'gist_id', name:'gist_id', value:@id}
    %input{type:'submit', value:'Generate'}
- if @gist
  %h2 Embed Code
  %small= %{Owner: %s} % @gist.data['owner']
  %small= %{Description: %s} % (@gist.data['description'] || 'n/a')
  %a{id:'select', href:'#'} Select Embed Code
  %pre#embed
    = escape_html(@gist.script)
    = preserve "\n\n&lt;noscript>\n"+escape_html(@gist.raw)+"\n&lt;/noscript>"
  %h2 Gist Preview
  = @gist.script