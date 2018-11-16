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
# Test these settings with:    <CentOS equivalent of "sudo apache2ctl configtest">
# Reload these settings with:  <CentOS equivalent of "sudo service apache2 reload">

# NOTE:  The SERVICE_PATH should match that found in Dockerfile and Dockerfile-test
SERVICE_PATH=plot-service/v1
SERVICE_PATH_TEST=plot-service/test

# ---- . ---- . updated to use MazamaCoreUtils
VERSION=1.0.1

# DESKTOP version -------------------------------------------------------------

# NOTE:  DESKTOP reuses Dockerfile-test but has a separate docker-compse-desktop.yml
desktop_build:
	-mkdir plot-service/output
	cd plot-service; docker build -t plot-service-desktop:$(VERSION) -t plot-service-desktop:latest -f Dockerfile-test .

desktop_up:
	docker-compose -f docker-compose-desktop.yml -p plotservicedesktop up -d

desktop_down:
	docker-compose -f docker-compose-desktop.yml -p plotservicedesktop down

desktop_container_logs:
	docker-compose -f docker-compose-desktop.yml -p plotservicedesktop logs -f

desktop_bounce: desktop_down desktop_up

desktop_reboot: desktop_down desktop_build desktop_up


# TEST version -----------------------------------------------------------------

test_build:
	-mkdir plot-service/output
	cd plot-service; docker build -t plot-service-test:$(VERSION) -t plot-service-test:latest -f Dockerfile-test .

test_up:
	docker-compose -f docker-compose-test.yml -p plotservicetest up -d

test_down:
	docker-compose -f docker-compose-test.yml -p plotservicetest down

test_container_logs:
	docker-compose -f docker-compose.yml -p plotservicetest logs

test_trace_log:
	cat /var/log/$(SERVICE_PATH_TEST)/app/TRACE.log

test_debug_log:
	cat /var/log/$(SERVICE_PATH_TEST)/app/DEBUG.log

test_info_log:
	cat /var/log/$(SERVICE_PATH_TEST)/app/INFO.log

test_error_log:
	cat /var/log/$(SERVICE_PATH_TEST)/app/ERROR.log

test_bounce: test_down test_up

test_reboot: test_down test_build test_up


# PRODUCTION version ----------------------------------------------------------

production_build:
	-mkdir plot-service/output
	cd plot-service; docker build -t plot-service-v1:$(VERSION) -t plot-service-v1:latest -f Dockerfile-v1 .

production_up:
	docker-compose -f docker-compose-v1.yml -p plotservicev1 up -d

production_down:
	docker-compose -f docker-compose-v1.yml -p plotservicev1 down

production_container_logs:
	docker-compose -f docker-compose-v1.yml -p plotservicev1 logs

production_trace_log:
	cat /var/log/$(SERVICE_PATH)/app/TRACE.log

production_debug_log:
	cat /var/log/$(SERVICE_PATH)/app/DEBUG.log

production_info_log:
	cat /var/log/$(SERVICE_PATH)/app/INFO.log

production_error_log:
	cat /var/log/$(SERVICE_PATH)/app/ERROR.log

production_bounce: production_down production_up

production_reboot: production_down production_build production_up

