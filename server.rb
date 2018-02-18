require 'sinatra'
require 'json'
require './page'
require 'net/http'
require 'base64'

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

  def quote (string)
    # replacing \n with space should reverse all substitutions
    string = string.gsub(/^([\w-]+) ([\w-]+)$/, '\1\n\2')
    string = string.gsub(/^([\w-]+) ([\w-]+) ([\w-]+)$/, '\1 \2\n\3')
    string = string.gsub(/^([\w-]+) ([\w-]+) ([\w-]+) ([\w-]+)$/, '\1 \2\n\3 \4')
    string = string.gsub(/^([\w-]+) ([\w-]+) ([\w-]+) ([\w-]+) ([\w-]+)$/, '\1 \2 \3\n\4 \5')
    string = string.gsub(/^(.*?)\((.*?)\)(.*)$/, '\1\n(\2)\n\3')
    string = string.gsub(/^([\w-]+) ([\w-]+\.?) ([\w-]+) ([\w-]+)$/, '\1 \2\n\3 \4')
    string = string.gsub(/^(Union of) (.*)$/, '\1\n\2')
    "\"#{string}\""
  end

  def merge (graphs)
    graph = Hash.new { |hash, key| hash[key] = [] }
    graphs.each do | obj |
      obj.each do | from, tos |
        have = graph[from]
        graph[from] = [have, tos].flatten.uniq
      end
    end
    graph
  end

  def dot (graph, style)
    dot = []
    if style=='files'
      (graph.keys + graph.values).uniq.each do | node |
        dot << "#{quote node} [fillcolor=lightBlue]" if node =~ /activity/
        dot << "#{quote node} [fillcolor=bisque]" if node =~ /sites|scrape/
        dot << "#{quote node} [style=\"filled,rounded\"]" if node =~ /page|file|directory|rollup/
      end
    end
    graph.each do | from, tos |
      tos.each do | to |
        dot << "#{quote from} -> #{quote to};"
      end
    end
    "digraph { node [shape=box style=filled fillcolor=paleGreen]; #{dot.join "\n"} }"
  end

  def svg (file, dot)
    `echo '#{dot}' | dot -Tsvg | tee public/#{file} | tail -n +7`
  end

end

before do
  response['Access-Control-Allow-Origin'] = '*'
end

# https://www.snip2code.com/Snippet/85077/Sinatra-with-cross-origin-AJAX-requests-
options '*' do
  headers 'Access-Control-Allow-Headers' => 'Accept, Authorization, Content-Type',
          'Access-Control-Allow-Methods' => 'GET, POST, PUT, PATCH, DELETE, OPTIONS, LINK, UNLINK',
          'Access-Control-Max-Age'       => '600'
end

get '/ls' do
  "<pre>" + `ls -la` + "\n" + `ls -la public`
end

get '/' do
<<EOF
  <html>
    <head>
      <link id='favicon' href='/favicon.png' rel='icon' type='image/png'>
    </head>
    <body style="padding:40px; text-align:center;">
      <h1>Image Transporter</h1>
      <p><a id=link target="_blank" href="http://ward.asia.wiki.org/">details</a></p>
      <script>
        link.href += location.host + "/welcome-visitors"
      </script>
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

post "/echo", :provides => :json do
  params = JSON.parse(request.env["rack.input"].read)
  page 'Transport Parameters' do
    paragraph "These are all of the parameters sent in the post body of the transport request."
    item 'html', {:text => "<pre>#{JSON.pretty_generate params}"}
  end
end

post "/clean", :provides => :json do
  begin
    params = JSON.parse(request.env["rack.input"].read)
    p = params['url'].split('/')
    slug = p[-1]
    site = p[-2] == 'view' ? p[2] : p[-2]
    page = JSON.parse Net::HTTP.get(site, "/#{slug}.json")
    want = page['story'].map{ |item| item['id'] }.uniq
    page['journal'] = page['journal'].select{ |action| !action['id'] or want.include? action['id'] }
    return JSON.pretty_generate page
  rescue
    page 'Oops' do
      paragraph "We expected a page's flag to be dropped for journal cleaning."
    end
  end
end

post "/graphviz", :provides => :json do
  style = params['style']
  params = JSON.parse(request.env["rack.input"].read)
  page 'Transported Graphviz' do
    mergeout = merge params
    outfile = "#{(rand(1000)+1000).to_s[-3..-1]}.svg"
    dotout = dot mergeout, style
    svgout = svg outfile, dotout
    paragraph "This graph represents the merge of all graph-source to the left of the transport page.
    Drag it to any page. Fetch a short-lived static file with the same svg diagram.
    [http://#{request.host_with_port}/#{outfile} page]"
    item 'html', {:text => "<img width=420 src='data:image/svg+xml;base64,#{Base64.encode64 svgout}'>"}
    item 'html', {:text => "<h3>Debug</h3>"}
    item 'html', {:text => "<pre>#{JSON.pretty_generate mergeout}</pre>"}
    item 'html', {:text => "<pre>#{dotout}</pre>"}
  end
end

get '/graphviz-gallery.json', :provides => :json do
  page 'Graphviz Gallery' do
    paragraph "We keep transported graphs until the random filename comes up for reuse."
    files = `cd public; ls -tr`.split("\n").select{|name| name=~/\.svg$/}
    links = files.map{|name| "[http://#{request.host_with_port}/#{name} #{name.gsub /\.svg/, ''}]"}
    paragraph links.join ' '
  end
end

post "/cite", :provides => :json do
  begin
    params = JSON.parse(request.env["rack.input"].read)
    p = params['url'].split('/')
    slug = p[-1]
    site = p[-2] == 'view' ? p[2] : p[-2]
    cited = JSON.parse Net::HTTP.get(site, "/#{slug}.json")
    page site do
      synopsis = cited['story'][0]['text'] || 'Add synopsis here.'
      paragraph synopsis[0..100]
      item 'reference', {:site => site, :title => cited['title'], :text => synopsis}
    end
  rescue
    page 'Oops' do
      paragraph "We expected a page's flag to be dropped for a directory citation. Params should include url of federated wiki page."
      item 'code', {:text => JSON.pretty_generate(params)}
    end
  end
end

get '/system/sitemap.json' do
  send_file 'status/sitemap.json'
end

get '/favicon.png' do
  send_file 'status/favicon.png'
end

get %r{/([a-z0-9-]+)\.json} do |slug|
  send_file "pages/#{slug}"
end

get %r{/view/} do
  redirect '/'
end
