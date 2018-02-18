FROM ruby:2.3

RUN gem install puma sinatra \
 && apt-get update \
 && apt-get -y install graphviz

USER 1000
COPY ./ /code
RUN mkdir /code/public
WORKDIR /code

CMD ["ruby", "server.rb"]
