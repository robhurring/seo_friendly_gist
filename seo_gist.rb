require "bundler"
Bundler.require

class SEOGist < Sinatra::Base
  enable :inline_templates
  
  get '/' do
    haml :index
  end
  
  post '/generate' do
  end
end

__END__
@@layout
%html
  %head
    %style
      body{background:#fafafa;}
  %body
    = yield

@@index
%p hai