#!/bin/sh
# chkconfig: 345 99 55
# description: script to start unicorn
# /etc/init.d/[application]_unicorn

# source functions library
. /etc/rc.d/init.d/functions

# source application params
. /etc/sysconfig/deployed_application

start() {
  local program
  local options
  local env_vars

  cd $ROOT_PATH

  env_vars="RAILS_ENV=$RAILS_ENV BUNDLE_GEMFILE=$BUNDLE_GEMFILE"
  options="-c $UNICORN_CONFIG -E $RAILS_ENV -D "
  program="source /home/$APP_USER/.bash_profile; $env_vars bundle exec unicorn $options"

  action 'Starting Unicorn...' daemon --user "${APP_USER#$USER}" --pidfile=$UNICORN_PIDFILE $program
}

stop() {
  local unicorn_pid

  unicorn_pid=$(cat $UNICORN_PIDFILE)

  if checkpid $unicorn_pid ; then
    action 'Stopping Unicorn...' kill -s QUIT $unicorn_pid
  else
    echo "Unicorn is not running"
  fi
}

restart() {
  local unicorn_pid restart_sleep

  restart_sleep=5

  echo "Restarting Unicorn..."

  if [ -f $UNICORN_PIDFILE ]; then
    unicorn_pid=$(cat $UNICORN_PIDFILE)

    action 'Clonning Master...' kill -s USR2 $unicorn_pid

    [ "${?}" -ne 0 ] && return $?

    sleep $restart_sleep

    if checkpid $unicorn_pid ; then
      action 'Killing old Master...' kill -s QUIT $unicorn_pid
    fi
  else
    echo "Unicorn is not running"
    start
    return $?
  fi
}

case "$1" in
  start) start ;;
  stop) stop ;;
  restart) restart ;;
  *)
    echo "Usage: $0 {start|stop|restart}"
    exit 1
esac

exit $?
