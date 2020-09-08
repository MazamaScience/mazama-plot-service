################################################################################
# Makefile for building and running docker containers
#
# On joule, ProxypPass settings are defined in:
#
#   /etc/httpd/conf.d/tools.mazamascience.com.conf
#
# # 6000-6009 plot-service -----------------------------------------------------
# # 6001 -- v1 operational
# # 6009 -- test (development)
# ProxyPass /plot-service/v1 http://127.0.0.1:6001/plot-service/v1
# ProxyPassReverse /plot-service/v1 http://127.0.0.1:6001/plot-service/v1
# ProxyPass /plot-service/test http://127.0.0.1:6009/plot-service/test
# ProxyPassReverse /plot-service/test http://127.0.0.1:6009/plot-service/test
#
# Test these settings with:    <Ubuntu: "sudo apache2ctl configtest">
# Reload these settings with:  <Ubuntu: "sudo service apache2 reload">
# 
# Test these settings with:    <CentOS: "sudo apachectl configtest">
# Reload these settings with:  <CentOS: "sudo apachectl graceful">

# ---- . beakr 0.3 . warning threshold
VERSION=1.2.1

# NOTE:  The SERVICE_PATH should match that found in Dockerfile and Dockerfile-test
SERVICE_PATH=plot-service/v1
SERVICE_PATH_TEST=plot-service/test

# ----- TESTING ----------------------------------------------------------------
 
clean:
	-rm -rf plot-service/data
	-rm -rf plot-service/logs
	-rm -rf plot-service/output


# ----- DESKTOP version --------------------------------------------------------

# NOTE:  DESKTOP reuses Dockerfile-test but has a separate docker-compse-desktop.yml
desktop_build:
	-mkdir plot-service/output
	cd ./plot-service; docker build -t plot-service-desktop:$(VERSION) -t plot-service-desktop:latest -f Dockerfile-test .

desktop_build_no-cache:
	-mkdir plot-service/output
	cd ./plot-service; docker build --no-cache -t plot-service-desktop:$(VERSION) -t plot-service-desktop:latest -f Dockerfile-test .

desktop_up:
	docker-compose -f docker/docker-compose-desktop.yml -p plotservicedesktop up -d

desktop_down:
	docker-compose -f docker/docker-compose-desktop.yml -p plotservicedesktop down

desktop_container_logs:
	docker-compose -f docker/docker-compose-desktop.yml -p plotservicedesktop logs -f

desktop_bounce: desktop_down desktop_up

desktop_reboot: desktop_build desktop_down desktop_up


# ----- TEST version -----------------------------------------------------------

test_build:
	-mkdir plot-service/output
	cd ./plot-service; docker build -t plot-service-test:$(VERSION) -t plot-service-test:latest -f Dockerfile-test .

test_build_no-cache:
	-mkdir plot-service/output
	cd ./plot-service; docker build --no-cache -t plot-service-test:$(VERSION) -t plot-service-test:latest -f Dockerfile-test .

test_up:
	docker-compose -f docker/docker-compose-test.yml -p plotservicetest up -d

test_down:
	docker-compose -f docker/docker-compose-test.yml -p plotservicetest down

test_container_logs:
	docker-compose -f docker/docker-compose-test.yml -p plotservicetest logs

test_trace_log:
	cat /var/log/$(SERVICE_PATH_TEST)/app/TRACE.log

test_debug_log:
	cat /var/log/$(SERVICE_PATH_TEST)/app/DEBUG.log

test_info_log:
	cat /var/log/$(SERVICE_PATH_TEST)/app/INFO.log

test_error_log:
	cat /var/log/$(SERVICE_PATH_TEST)/app/ERROR.log

test_bounce: test_down test_up

test_reboot: test_build test_down test_up


# ----- PRODUCTION version -----------------------------------------------------

production_install_dashboards:
	cp html/dashboards/server-health-dashboard.html /var/www/tools.mazamascience.com/html/
	cp html/dashboards/server-health-tools.html /var/www/tools.mazamascience.com/html/

production_build:
	-mkdir plot-service/output
	cd ./plot-service; docker build -t plot-service-v1:$(VERSION) -t plot-service-v1:latest -f Dockerfile-v1 .

production_build_no-cache:
	-mkdir plot-service/output
	cd ./plot-service; docker build --no-cache -t plot-service-v1:$(VERSION) -t plot-service-v1:latest -f Dockerfile-v1 .

production_up:
	docker-compose -f docker/docker-compose-v1.yml -p plotservicev1 up -d

production_down:
	docker-compose -f docker/docker-compose-v1.yml -p plotservicev1 down

production_container_logs:
	docker-compose -f docker/docker-compose-v1.yml -p plotservicev1 logs

production_trace_log:
	cat /var/log/$(SERVICE_PATH)/app/TRACE.log

production_debug_log:
	cat /var/log/$(SERVICE_PATH)/app/DEBUG.log

production_info_log:
	cat /var/log/$(SERVICE_PATH)/app/INFO.log

production_error_log:
	cat /var/log/$(SERVICE_PATH)/app/ERROR.log

production_bounce: production_down production_up

production_reboot: production_build production_down production_up

