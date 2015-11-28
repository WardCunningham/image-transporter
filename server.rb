require 'sinatra'
require 'json'
require './page'
require 'net/http'

set :bind, '0.0.0.0'
set :port, 4010

helpers do
  def transclude url
    image url, "Transported image. [#{url} source]"
    paragraph "Drag and drop this image into the desired page."
    paragraph "First double click the image to be sure you've found the desired size."
    paragraph "The larger image below has been marked up in the less easily edited html."

    item :html, {:text => <<END
<div style="
  padding: 12px;
  background:#eee;
  width:96%;
  align=centered;">

<img style="
  display:block;
  margin:auto;
  width:100%;"
  src="#{url}">

<p class=caption>
  Transported image.
  [#{url} source]
</p>
</div>
END
}
    paragraph "Remember, these images will be retrieved from a remote server with each viewing and may not be kept there long."
  end

end

before do
  response['Access-Control-Allow-Origin'] = '*'
end

# https://www.snip2code.com/Snippet/85077/Sinatra-with-cross-origin-AJAX-requests-
options '*' do
  headers 'Access-Control-Allow-Headers' => 'Accept, Authorization, Content-Type',
          'Access-Control-Allow-Methods' => 'GET, POST, PUT, PATCH, DELETE OPTIONS, LINK, UNLINK',
          'Access-Control-Max-Age'       => '600'
end


get '/' do
<<EOF
  <html>
    <head>
      <link id='favicon' href='/favicon.png' rel='icon' type='image/png'>
    </head>
    <body style="padding:40px; text-align:center;">
      <h1>Image Transporter</h1>
      <p><a href="http://ward.asia.wiki.org/transport-plugin.html">details</a></p>
    </body>
  </html>
EOF
end

post "/image", :provides => :json do
  params = JSON.parse(request.env["rack.input"].read)
  page 'Transported Image' do
    if params['html'].length == 0 and params['text'].length > 0
      transclude params['text']
    elsif params['html'].match /src="(.*?)"/
      transclude $1
    elsif params['html'].match /href="(.*?)"/
      transclude $1
    else
      paragraph "Couldn't fine src or href field."
      paragraph "text: #{params['text']}"
      paragraph "html: #{params['html']}"
    end
    
  end
end

post "/flp", :provides => :json do
  params = JSON.parse(request.env["rack.input"].read)
  ignore, ignore, site, slug, ignore = params['text'].split('/')
  Net::HTTP.get(site, "/?fedwiki=#{slug}")
end

get '/system/sitemap.json' do
  send_file 'status/sitemap.json'
end

get '/favicon.png' do
  send_file 'status/favicon.png'
end

get %r{^/([a-z0-9-]+)\.json$} do |slug|
  send_file "pages/#{slug}"
end

get %r{^/view/} do
  redirect '/'
end
