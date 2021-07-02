FROM hexpm/elixir:1.12.1-erlang-23.2.1-ubuntu-focal-20201008

RUN apt-get update && apt-get install -y sudo curl
# https://stackoverflow.com/questions/44331836/apt-get-install-tzdata-noninteractive
RUN DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends tzdata

RUN curl -sL https://deb.nodesource.com/setup_14.x | bash -

# Create the non-root user
RUN adduser --disabled-password --gecos '' docker
RUN adduser docker sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
USER docker
RUN mkdir -p /home/docker/invoicer
WORKDIR /home/docker/invoicer

RUN sudo apt install -y git inotify-tools build-essential
RUN sudo apt install -y nodejs

RUN curl -LO https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
RUN sudo apt-get install -y ./google-chrome-stable_current_amd64.deb
RUN rm google-chrome-stable_current_amd64.deb

RUN mix local.rebar --force
RUN mix local.hex --force

COPY mix.exs .
COPY apps/invoicer_pdf/mix.exs ./apps/invoicer_pdf/mix.exs
COPY apps/invoicer_html/mix.exs ./apps/invoicer_html/mix.exs
COPY mix.lock .

# copy the deps for faster builds
COPY deps ./deps
COPY config ./config
RUN sudo chown -R docker:docker /home/docker
RUN ["mix", "deps.get"]
RUN ["mix", "deps.compile"]

# copy the _build for faster builds
COPY _build ./_build
COPY apps/invoicer_pdf/lib ./apps/invoicer_pdf/lib
COPY apps/invoicer_pdf/test ./apps/invoicer_pdf/test
COPY apps/invoicer_html/lib ./apps/invoicer_html/lib
COPY apps/invoicer_html/test ./apps/invoicer_html/test
COPY apps/invoicer_html/assets ./apps/invoicer_html/assets
COPY apps/invoicer_html/priv ./apps/invoicer_html/priv

RUN sudo chown -R docker:docker /home/docker
WORKDIR /home/docker/invoicer/apps/invoicer_html/assets
RUN ["npm", "install"]
WORKDIR /home/docker/invoicer

RUN sudo chown -R docker:docker /home/docker
RUN ["mix", "compile"]

COPY entrypoint.sh ./entrypoint.sh
COPY .iex.exs .iex.exs

ENTRYPOINT ["/bin/bash", "entrypoint.sh"]
