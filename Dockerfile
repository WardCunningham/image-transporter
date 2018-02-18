FROM ruby:2.3

RUN gem install puma sinatra \
 && apt-get update \
 && apt-get -y install graphviz

COPY ./ /code
RUN mkdir /code/public
USER 1000
WORKDIR /code

CMD ["ruby", "server.rb"]
