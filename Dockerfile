FROM ruby:2.3

RUN gem install puma sinatra \
 && apt-get update \
 && apt-get -y install graphviz

RUN mkdir /code/public && ls -l /code

USER 1000
COPY ./ /code
WORKDIR /code

CMD ["ruby", "server.rb"]
