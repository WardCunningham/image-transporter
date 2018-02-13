FROM ruby:2.3

RUN gem install puma sinatra
RUN apt-get update
RUN apt-get -y install graphviz

USER 1000
COPY ./ /code
WORKDIR /code
CMD mkdir public

CMD ["ruby", "server.rb"]