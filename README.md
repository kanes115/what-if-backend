# WhatIf

TODO Descritpion here

## Installation

### Prerequisites
* Docker
* Erlang
* Elixir
* node.js

### Docker compose
First you need to set up your database. Type in terminal:
```
$ docker-compose up -d
```
and then, everytime you need to start your database container (and other services in the future) type:
```
$ docker-compose start
```
in order to stop your backend:
```
$ docker-compose stop
```
*NOTE*
If you install postgres on your own, be sure to set up config/* files accoridngly.

### Migrate
In order to create a database in Postgre, type:
```
$ mix ecto.create
```
and fill them up with tables:
```
$ mix ecto.migrate
```

### Dependencies
Install dependencies executing:
```
$ mix deps.get
$ npm install
```
## Usage
To start the application: `mix phoenix.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.
