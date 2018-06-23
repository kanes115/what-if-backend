FROM phusion/baseimage

ENV VSN=master \
    BUILD_DEPS="git make gcc wget esl-erlang=1:20.3 elixir=1.6.5-1 npm" \
    PORT="80" \
    HOST="ec2-18-219-114-131.us-east-2.compute.amazonaws.com" \
    RELEASE_PATH=/usr/lib/what-if-backend

ADD prod.secret.exs /prod.secret.exs
ADD prod.exs /prod.exs

RUN curl -O https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb && \
    echo $RELEASE_PATH && \
    dpkg -i erlang-solutions_1.0_all.deb && \
    apt-get update && \
    apt-get install -y ${BUILD_DEPS} ${RUN_DEPS} && \
    apt-get install -y libtool autoconf tree && \
    echo "ERLANG VERSION: " && \
    erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().'  -noshell && \
    mix local.hex --force && \
    mix local.rebar --force && \
    git clone https://github.com/kanes115/what-if-backend.git --branch ${VSN} && \
    mv /prod.secret.exs /what-if-backend/config/prod.secret.exs && \
    mv /prod.exs /what-if-backend/config/prod.exs && \
    cd what-if-backend && \
    mix deps.get && \
    MIX_ENV=prod mix compile && \
    npm install && ln -s /usr/bin/nodejs /usr/bin/node && \
    node_modules/brunch/bin/brunch build && \
    MIX_ENV=prod mix phoenix.digest && \
    MIX_ENV=prod mix release.init && \
    MIX_ENV=prod mix release --env=prod && \
    mkdir ${RELEASE_PATH} && \
    tree ./_build/prod/rel/what_if/releases && \
    tar xvf ./_build/prod/rel/what_if/releases/*/what_if.tar.gz -C ${RELEASE_PATH} && \
    rm -rf /what-if-backend erlang-solutions* && \
    apt-get purge -y --auto-remove $BUILD_DEPS

EXPOSE 80

ADD run.sh /run.sh

CMD ["bash", "/run.sh"]
