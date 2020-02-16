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
├── README_THIS_IS_GIT_BRANCH_master
├── docker
│   ├── docker-compose-desktop.yml
│   ├── docker-compose-test.yml
│   └── docker-compose-v1.yml
├── mazama-plot-service.Rproj
└── plot-service
    ├── Dockerfile-test
    ├── Dockerfile-v1
    └── R
        ├── plot-service-app.R
        ├── server-load
        │   ├── createDataList.R
        │   ├── createInfoList.R
        │   ├── createProduct.R
        │   ├── createTextList_en.R
        │   └── createTextList_es.R
        └── sharedUtils
            └── createAPIList.R
```

A single `server-load` _sub-service_ is defined with all relevant R scripts
located in `plot-service/R/server-load/`.

## Running the app from RStudio ##

Inside RStudio you can run the app with:

 * `cd plot-service/`
 * "Files > More > Set As Working Directory"
 * open up `R/plot-service-app.R`
 * set breakpoints if desired
 * click the 'Source' button

The app will be available at:

[localhost:8080/plot-service/dev/](localhost:8080/plot-service/dev/)

## Running the app with Docker ##

You can create and run a docker image with the app by:

 * typing `make desktop_reboot`
 
The app will be available at:

[localhost:8080/plot-service/test/](localhost:8080/plot-service/test/)
 
The `Makefile` has targets for three different types of deployment: 
`desktop`, `test`, `operational`.

A quick refresher on docker commands is available at the 
[docker cheatsheet](https://github.com/wsargent/docker-cheat-sheet).

## Host Computer Settings ##

### Log Files ###

Log files will be written to a directory named after the deployment type:

`/var/log/plot-service/test/app` or `/var/log/plot-service/operational/app`

except for `desktop` which are written to:

`plot-service/logs`

### ProxyPass Settings ###

On AWS instances, ProxyPass settings are defined in:

`/etc/apache2/sites-enabled/default-ssl.conf`

## Testing the app ##

You can ask to see the `api` by hitting the service with no sub-service
specified:

[http://localhost:8080/plot-service/dev](http://localhost:8080/plot-service/dev)

You can ask for a `plot`:

[http://localhost:8080/plot-service/dev/server-load?serverid=joule.mazamascience.com](http://localhost:8080/plot-service/dev/server-load?serverid=joule.mazamascience.com)

***
