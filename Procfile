web:        bundle exec rackup -s puma -p $PORT -E development
worker:     bundle exec rake resque:work
scheduler:  bundle exec rake resque:scheduler
#resque:    bundle exec resque-web -p 8282
