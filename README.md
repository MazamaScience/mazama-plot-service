# plot-service #

This directory contains a dockerizable webservice that runs R
code and returns various types of plots.

## Reboot Instructions for an Operational Site

```make production_bounce```

*(Yes, that's it.)*

***
***

Now for the gory details.

## Files ##

The basic files required for a product-only webservice (no UI) are the following:

```
├── Makefile
├── NEWS.md
├── README.md
├── docker-compose-desktop.yml
├── docker-compose-test.yml
├── docker-compose.yml
└── plot-service/
    ├── Dockerfile
    ├── Dockerfile-test
    ├── R/
    ├── logs/
    ├── plot-service-app.R
    └── output/
```

## Running the app from RStudio ##

Outside of RStudio you must first:

 * `make desktop_download_data`

Inside RStudio you can run the app with:

 * `cd plot-service/`
 * "Set As Working Directoroy"
 * open up `plot-service-app.R`
 * set breakpoints if desired
 * click the 'Source' button

The app will be available at:

[localhost:8080/plot-service/dev/](localhost:8080/plot-service/dev/)

## Running the app with Docker ##

You can create and run a docker image with the app by:

 * typing `make desktop_reboot`
 
The app will be available at:

[localhost:8080/plot-service/test/](localhost:8080/plot-service/test/)
 
The `Makefile` has targets for three different types of deployment: `desktop`, 
`test`, `operational`.

A quick refresher on docker commands is available at the 
[docker cheatsheet](https://github.com/wsargent/docker-cheat-sheet).

## Host Computer Settings ##

### Log Files ###

Log files will be written to a directory named after the deployment type:

`/var/log/plot-service/test/app` or `/var/log/plot-service/operational/app`

except for `desktop` which are written to:

`plot-service/logs`

### ProxyPass Settings ###

On the computer 'haze', ProxyPass settings are defined in:

`/etc/apache2/sites-enabled/default-ssl.conf`

## Testing the app ##

You can ask to see the `api` by hitting the service with no sub-service
specified:

[http://localhost:8080/plot-service/dev](http://localhost:8080/plot-service/dev)

You can ask for a `plot`:

[http://localhost:8080/plot-service/dev/server-load?serverid=joule.mazamascience.com](http://localhost:8080/plot-service/dev/server-load?serverid=joule.mazamascience.com)

***
