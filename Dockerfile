FROM erlang:24
RUN apt update && apt-get install -y redis-server=5:5.0.3-4+deb10u3
# Remve old rebar
RUN rm /usr/local/bin/rebar
